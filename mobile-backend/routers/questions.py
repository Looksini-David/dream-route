import uuid
from fastapi import APIRouter, Body, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Questions, QuizSubmission, Quizzes, User, UserQuizAttempts, ResumeRules, Skills
import random
from auth import get_current_user
from collections import defaultdict
from typing import Optional, List
from pydantic import BaseModel

router = APIRouter(prefix="/questions", tags=["Questions"])

# ============================================================
# HELPER: Analyze resume automatically when domain is set
# ============================================================
def auto_analyze_resume(user_id: str, domain: str, db: Session):
    """
    Automatically analyze a user's resume once their quiz domain is determined.
    This is called after quiz submission when best_domain is set.
    """
    try:
        # Import here to avoid circular imports
        from routers.resume_analysis import extract_text_from_pdf, normalize_skill
        
        # Get the pending resume for this user
        rule = db.query(ResumeRules).filter(
            ResumeRules.user_id == user_id,
            ResumeRules.analysis_status == "pending"
        ).order_by(ResumeRules.created_at.desc()).first()
        
        if not rule or not rule.resume_blob:
            print(f"No pending resume found for user {user_id}")
            return
        
        # Extract text from resume
        resume_text = extract_text_from_pdf(rule.resume_blob)
        if not resume_text:
            print(f"Could not extract text from resume for user {user_id}")
            return
        
        # Get skills for the domain
        skill_rows = db.query(Skills).filter(Skills.domain == domain).all()
        domain_skill_list = []
        
        for row in skill_rows:
            if row.description:
                split_skills = [s.strip() for s in row.description.split(",")]
                domain_skill_list.extend(split_skills)
        
        if not domain_skill_list:
            print(f"No skills found for domain {domain}")
            return
        
        # Match skills
        normalized_resume = normalize_skill(resume_text)
        domain_skill_list = list(set([normalize_skill(s) for s in domain_skill_list]))
        
        matched = []
        missing = []
        
        for skill in domain_skill_list:
            if skill in normalized_resume:
                matched.append(skill)
            else:
                missing.append(skill)
        
        # Calculate score
        score = int((len(matched) / len(domain_skill_list)) * 100) if domain_skill_list else 0
        
        # Update ResumeRules with analysis results
        rule.score = score
        rule.matched_skills = ",".join(matched)
        rule.missing_skills = ",".join(missing)
        rule.domain = domain
        rule.analysis_status = "completed"
        db.add(rule)
        db.commit()
        
        # Update User summary
        user = db.query(User).filter(User.user_id == user_id).first()
        if user:
            user.resume_score = score
            user.skills = ",".join(matched)
            db.add(user)
            db.commit()
        
        print(f"✓ Resume analyzed automatically for user {user_id} with domain {domain}")
        
    except Exception as e:
        db.rollback()
        print(f"Error auto-analyzing resume: {e}")

# ============================================================
# PYDANTIC MODELS
# ============================================================
class TiebreakerQuestionsRequest(BaseModel):
    tied_domains: List[str]
    userType: Optional[str] = "fresher"

class TiebreakerRequest(BaseModel):
    submission: QuizSubmission
    tied_domains: List[str]

# ------------------------ Fetch Questions ------------------------ #
@router.get("/")
def get_questions(userType: str, db: Session = Depends(get_db), domains: Optional[list[str]] = None):
    """
    Fetch 3 random questions per domain for a user.
    Optional: domains → only fetch for these domains (used for tiebreaker)
    """
    user_types_map = {
        "student": ["creativity", "logical_thinking", "communication"],
        "fresher": ["technical", "situational", "softskill"]
    }

    if userType.lower() not in user_types_map:
        raise HTTPException(status_code=400, detail="Invalid userType")

    q_types = user_types_map[userType.lower()]
    all_questions = []

    # Fetch quizzes grouped by domain
    quizzes = db.query(Quizzes).all()
    domain_map = defaultdict(list)
    for quiz in quizzes:
        if domains and quiz.domain not in domains:
            continue
        domain_map[quiz.domain].append(quiz.quiz_id)

    # Fetch questions for each domain
    for domain, quiz_ids in domain_map.items():
        questions = (
            db.query(Questions)
            .filter(
                Questions.quiz_id.in_(quiz_ids),
                Questions.type.in_(q_types)
            )
            .all()
        )
        if not questions:
            continue

        selected = random.sample(questions, min(3, len(questions)))
        all_questions.extend(selected)

    random.shuffle(all_questions)

    return [
        {
            "question_id": q.question_id,
            "quiz_id": q.quiz_id,
            "question_text": q.question_text,
            "option_a": q.option_a,
            "option_b": q.option_b,
            "option_c": q.option_c,
            "option_d": q.option_d,
            "type": q.type.value if hasattr(q.type, 'value') else q.type,
        }
        for q in all_questions
    ]


# ------------------------ Submit Quiz ------------------------ #
@router.post("/submit-quiz")
def submit_quiz(
    submission: QuizSubmission,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not submission.answers:
        raise HTTPException(status_code=400, detail="No answers submitted")

    total = len(submission.answers)
    correct = 0
    domain_scores = defaultdict(list)

    # Track correct answers per domain
    for ans in submission.answers:
        q = db.query(Questions).filter(Questions.question_id == ans.question_id).first()
        if not q:
            raise HTTPException(status_code=404, detail=f"Question {ans.question_id} not found")

        is_correct = q.correct_option.value == ans.selected_option
        correct += is_correct

        quiz = db.query(Quizzes).filter(Quizzes.quiz_id == q.quiz_id).first()
        if quiz:
            domain_scores[quiz.domain].append(1 if is_correct else 0)

    score = round((correct / total) * 100)

    if score < 40:
        readiness = "beginner"
    elif score < 70:
        readiness = "medium"
    else:
        readiness = "high"

    user_id = current_user.user_id
    first_question = db.query(Questions).filter(Questions.question_id == submission.answers[0].question_id).first()
    quiz_id = first_question.quiz_id if first_question else None

    domain_avg = {domain: round(sum(scores)/len(scores)*100, 2) for domain, scores in domain_scores.items()}
    domain_scores_list = [{"domain": domain, "score": score} for domain, score in domain_avg.items()]

    # ------------------------ Tiebreaker Logic ------------------------ #
    max_score = max(domain_avg.values(), default=0)
    top_domains = [domain for domain, score in domain_avg.items() if score == max_score]

    tiebreaker_required = False
    best_domain_str = None

    if len(top_domains) == 1:
        best_domain_str = top_domains[0]
    elif len(top_domains) > 1:
        # Check if the max score is significant (> 0), if so, require tiebreaker
        if max_score > 0:
            tiebreaker_required = True
        else:
            # If all scores are 0, pick the first domain as default
            best_domain_str = top_domains[0] if top_domains else None

    # ------------------------ Store attempt in DB ------------------------ #
    new_attempt = UserQuizAttempts(
        user_id=user_id,
        quiz_id=quiz_id,
        score=score,
        readiness_level=readiness,
        best_domain=best_domain_str,
        ai_data_science=domain_avg.get("AI & Data Science", 0),
        data_analytics=domain_avg.get("Data Analytics", 0),
        it_management=domain_avg.get("IT Management", 0),
        database=domain_avg.get("Database", 0),
        cloud_devops=domain_avg.get("Cloud & DevOps", 0),
        software_development=domain_avg.get("Software Development", 0),
        networking=domain_avg.get("Networking", 0),
        mobile_development=domain_avg.get("Mobile Development", 0),
        design=domain_avg.get("Design", 0),
        cybersecurity=domain_avg.get("Cybersecurity", 0),
        web_development=domain_avg.get("Web Development", 0)
    )

    db.add(new_attempt)
    db.commit()
    db.refresh(new_attempt)

    # When a best domain is determined, ensure ResumeRules.domain is updated for this user
    if new_attempt.best_domain:
        try:
            rr = db.query(ResumeRules).filter(ResumeRules.user_id == user_id).order_by(ResumeRules.created_at.desc()).first()
            if rr:
                rr.domain = new_attempt.best_domain
                db.add(rr)
                db.commit()
            else:
                # Create a ResumeRules entry if one does not exist
                rr = ResumeRules(user_id=user_id, domain=new_attempt.best_domain)
                db.add(rr)
                db.commit()
            
            # ===== AUTOMATICALLY ANALYZE RESUME =====
            auto_analyze_resume(user_id, new_attempt.best_domain, db)
            
        except Exception as e:
            db.rollback()
            print(f"Error updating ResumeRules domain: {e}")

    return {
        "score": score,
        "readiness": readiness,
        "best_domain": best_domain_str,      # single domain if resolved
        "top_domains": top_domains,           # all tied domains for frontend
        "tiebreaker_required": tiebreaker_required,
        "domain_scores": domain_scores_list
    }

# ------------------------ Fetch Tiebreaker Questions ------------------------ #
@router.post("/tiebreaker-questions")
def get_tiebreaker_questions(
    request: TiebreakerQuestionsRequest,
    db: Session = Depends(get_db)
):
    """
    Fetch 2 random tiebreaker questions for each tied domain.
    """
    user_types_map = {
        "student": ["creativity", "logical_thinking", "communication"],
        "fresher": ["technical", "situational", "softskill"]
    }

    q_types = user_types_map.get(request.userType.lower(), ["technical", "situational", "softskill"])
    all_questions = []

    for domain in request.tied_domains:
        quizzes = db.query(Quizzes).filter(Quizzes.domain == domain).all()
        quiz_ids = [q.quiz_id for q in quizzes]

        if not quiz_ids:
            continue

        questions = (
            db.query(Questions)
            .filter(
                Questions.quiz_id.in_(quiz_ids),
                Questions.type.in_(q_types)
            )
            .all()
        )
        if not questions:
            continue

        selected = random.sample(questions, min(2, len(questions)))
        all_questions.extend(selected)

    return {
        "tiebreaker_questions": [
            {
                "question_id": q.question_id,
                "quiz_id": q.quiz_id,
                "question_text": q.question_text,
                "option_a": q.option_a,
                "option_b": q.option_b,
                "option_c": q.option_c,
                "option_d": q.option_d,
                "type": q.type.value if hasattr(q.type, 'value') else q.type,
            }
            for q in all_questions
        ]
    }

# ------------------------ Submit Tiebreaker ------------------------ #

@router.post("/tiebreaker")
def submit_tiebreaker(
    data: TiebreakerRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    submission = data.submission
    tied_domains = data.tied_domains

    if not submission.answers or not tied_domains:
        raise HTTPException(status_code=400, detail="No answers submitted or no tied domains")

    # Count previous tiebreaker attempts
    tiebreaker_count = db.query(UserQuizAttempts).filter(
        UserQuizAttempts.user_id == current_user.user_id,
        UserQuizAttempts.quiz_id == "TB001"
    ).count()
    
    current_round = tiebreaker_count + 1

    domain_scores = defaultdict(list)

    for ans in submission.answers:
        q = db.query(Questions).filter(Questions.question_id == ans.question_id).first()
        if not q:
            raise HTTPException(status_code=404, detail=f"Question {ans.question_id} not found")

        is_correct = q.correct_option.value == ans.selected_option

        quiz = db.query(Quizzes).filter(Quizzes.quiz_id == q.quiz_id).first()
        if quiz and quiz.domain in tied_domains:
            domain_scores[quiz.domain].append(1 if is_correct else 0)

    # Calculate domain averages
    domain_avg = {domain: round(sum(scores)/len(scores)*100, 2) for domain, scores in domain_scores.items()}

    # Check if still tied after this tiebreaker round
    max_score = max(domain_avg.values(), default=0)
    top_domains = [domain for domain, score in domain_avg.items() if score == max_score]
    
    still_tied = len(top_domains) > 1
    best_domain_str = None
    
    if not still_tied:
        # Tie resolved!
        best_domain_str = top_domains[0]
    elif current_round >= 3:
        # Maximum rounds reached, need user preference
        best_domain_str = None  # Will be set by user preference
    else:
        # Apply priority for this round but prepare for next round
        priority = [
            "AI & Data Science",
            "Data Analytics", 
            "Networking",
            "Mobile Development",
            "Software Development",
            "Cloud & DevOps",
            "Web Development",
            "Cybersecurity",
            "Database",
            "Design",
            "IT Management"
        ]
        best_domain_str = next((d for d in priority if d in top_domains), None)

    # ------------------------ SAVE TIEBREAKER ATTEMPT ------------------------ #
    try:
        # Check if TB001 quiz exists, create if not
        tiebreaker_quiz = db.query(Quizzes).filter(Quizzes.quiz_id == "TB001").first()
        if not tiebreaker_quiz:
            from datetime import datetime
            tiebreaker_quiz = Quizzes(
                quiz_id="TB001", 
                domain="Tiebreaker",
                title="Tiebreaker Quiz for Domain Resolution",
                created_at=datetime.now()
            )
            db.add(tiebreaker_quiz)
            db.flush()  # Flush to get the quiz_id available for foreign key
        
        new_attempt = UserQuizAttempts(
            user_id=current_user.user_id,
            quiz_id="TB001",  # special identifier for tiebreaker quizzes
            score=max(domain_avg.values(), default=0),
            readiness_level="high",  # Use valid constraint value instead of "Tiebreaker Round X"
            best_domain=best_domain_str,
            ai_data_science=domain_avg.get("AI & Data Science", 0),
            data_analytics=domain_avg.get("Data Analytics", 0),
            it_management=domain_avg.get("IT Management", 0),
            database=domain_avg.get("Database", 0),
            cloud_devops=domain_avg.get("Cloud & DevOps", 0),
            software_development=domain_avg.get("Software Development", 0),
            networking=domain_avg.get("Networking", 0),
            mobile_development=domain_avg.get("Mobile Development", 0),
            design=domain_avg.get("Design", 0),
            cybersecurity=domain_avg.get("Cybersecurity", 0),
            web_development=domain_avg.get("Web Development", 0)
        )

        db.add(new_attempt)
        db.commit()
        db.refresh(new_attempt)
    except Exception as e:
        db.rollback()
        print(f"Error saving tiebreaker attempt: {e}")
        raise

    # Update ResumeRules.domain if tie was resolved and best_domain is set
    if new_attempt.best_domain:
        try:
            rr = db.query(ResumeRules).filter(ResumeRules.user_id == current_user.user_id).order_by(ResumeRules.created_at.desc()).first()
            if rr:
                rr.domain = new_attempt.best_domain
                db.add(rr)
                db.commit()
            else:
                rr = ResumeRules(user_id=current_user.user_id, domain=new_attempt.best_domain)
                db.add(rr)
                db.commit()
            
            # ===== AUTOMATICALLY ANALYZE RESUME =====
            auto_analyze_resume(current_user.user_id, new_attempt.best_domain, db)
            
        except Exception as e:
            db.rollback()
            print(f"Error updating ResumeRules domain: {e}")

    return {
        "best_domain": best_domain_str,
        "domain_scores": [{"domain": domain, "score": score} for domain, score in domain_avg.items()],
        "still_tied": still_tied,
        "tied_domains": top_domains if still_tied else [],
        "round": current_round,
        "max_rounds_reached": current_round >= 3 and still_tied
    }

@router.post("/user-preference")
def submit_user_preference(preference_data: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    chosen_domain = preference_data.get("chosen_domain")
    
    if not chosen_domain:
        raise HTTPException(status_code=400, detail="Chosen domain is required")
    
    # Update the latest tiebreaker attempt with user's preference
    latest_tiebreaker = db.query(UserQuizAttempts).filter(
        UserQuizAttempts.user_id == current_user.user_id,
        UserQuizAttempts.quiz_id == "TB001"
    ).order_by(UserQuizAttempts.taken_on.desc()).first()
    
    if latest_tiebreaker:
        latest_tiebreaker.best_domain = chosen_domain
        latest_tiebreaker.readiness_level = "high"  # Use valid constraint value
        db.commit()

        # Also update ResumeRules.domain for this user
        try:
            rr = db.query(ResumeRules).filter(ResumeRules.user_id == current_user.user_id).order_by(ResumeRules.created_at.desc()).first()
            if rr:
                rr.domain = chosen_domain
                db.add(rr)
                db.commit()
            else:
                rr = ResumeRules(user_id=current_user.user_id, domain=chosen_domain)
                db.add(rr)
                db.commit()
            
            # ===== AUTOMATICALLY ANALYZE RESUME =====
            auto_analyze_resume(current_user.user_id, chosen_domain, db)
            
        except Exception as e:
            db.rollback()
            print(f"Error updating ResumeRules domain from user preference: {e}")
    
    return {
        "success": True,
        "best_domain": chosen_domain,
        "message": "User preference saved successfully"
    }
