# services/resume_analysis_backend.py
from sqlalchemy.orm import Session
from datetime import datetime
from models import ResumeRules, User, Skills, UserQuizAttempts
# from services.resume_service import analyze_resume
from services.resume_ats import analyze_ats
from services.resume_feedback import generate_ai_feedback

def analyze_resume_backend(rule_id: str, db: Session):
    """
    Analyze a resume based on user's best domain and update ResumeRules & User.
    """
    # Fetch ResumeRules record
    rule = db.query(ResumeRules).filter(ResumeRules.rule_id == rule_id).first()
    if not rule:
        print(f"No ResumeRules found for rule_id: {rule_id}")
        return None
    if not rule.resume_blob:
        print(f"No resume uploaded for rule_id: {rule_id}")
        return None

    # Get user's best domain from latest quiz attempt
    best_attempt = (
        db.query(UserQuizAttempts)
        .filter(UserQuizAttempts.user_id == rule.user_id)
        .order_by(UserQuizAttempts.taken_on.desc())
        .first()
    )
    domain = best_attempt.best_domain if best_attempt and best_attempt.best_domain else "software_development"

    # Collect domain skills
    skill_rows = db.query(Skills).filter(Skills.domain == domain).all()
    domain_skill_list = []
    for r in skill_rows:
        if r.description:
            domain_skill_list.extend([s.strip() for s in r.description.split(",") if s.strip()])
        else:
            domain_skill_list.append(r.skill_name)
    domain_skill_list = list(dict.fromkeys(domain_skill_list))  # remove duplicates

    # Analyze resume
    # result = analyze_resume(rule.resume_blob, domain_skill_list)
    result = analyze_ats(rule.resume_blob, domain_skill_list)
    
    # Generate AI feedback
    ai_feedback_data = generate_ai_feedback(result, domain)
    result["ai_feedback"] = ai_feedback_data["feedback"]
    result["tips"] = ai_feedback_data["tips"]

    try:
        # Update ResumeRules
        rule.score = result.get("ats_score", 0)  # Use ats_score from analyze_ats
        rule.matched_skills = ",".join(result.get("matched_skills", []))
        rule.missing_skills = ",".join(result.get("missing_skills", []))
        rule.domain = domain
        rule.analysis_status = "completed"
        rule.analyzed_at = datetime.utcnow()
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Error updating ResumeRules: {e}")
        return None

    # Update User
    user = db.query(User).filter(User.user_id == rule.user_id).first()
    if user:
        try:
            user.resume_score = result.get("ats_score", 0)
            user.skills = ",".join(result.get("matched_skills", []))
            db.commit()
        except Exception as e:
            db.rollback()
            print(f"Error updating User skills: {e}")

    return result