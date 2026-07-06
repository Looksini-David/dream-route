# routers/resume_analysis.py
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, Response
from sqlalchemy.orm import Session
from database import get_db
from models import User, ResumeRules, UserQuizAttempts, Skills
from auth import get_current_user
from services.resume_analysis_backend import analyze_resume_backend
from services.resume_feedback import generate_ai_feedback
from services.resume_ats import analyze_ats
from fastapi.responses import StreamingResponse
from io import BytesIO

router = APIRouter(prefix="/resume", tags=["resume"])

# ---------------- Upload Resume ----------------
@router.post("/upload")
async def upload_resume(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    content = await file.read()
    user = db.query(User).filter(User.user_id == current_user.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.resume_blob = content
    user.resume_url = file.filename
    db.commit()

    # Save or update ResumeRules
    rule = db.query(ResumeRules).filter(ResumeRules.user_id == user.user_id).first()
    if not rule:
        rule = ResumeRules(
            user_id=user.user_id,
            resume_blob=content,
            resume_url=file.filename,
            analysis_status="pending"
        )
        db.add(rule)
    else:
        rule.resume_blob = content
        rule.resume_url = file.filename
        rule.analysis_status = "pending"
    db.commit()
    return {"rule_id": rule.rule_id}


# ---------------- Analyze Resume ----------------
@router.post("/analyze/{rule_id}")
def analyze(
    rule_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    rule = db.query(ResumeRules).filter(ResumeRules.rule_id == rule_id).first()
    if not rule or not rule.resume_blob:
        raise HTTPException(status_code=404, detail="No resume found")

    result = analyze_resume_backend(rule_id, db)
    if not result:
        raise HTTPException(status_code=500, detail="Failed to analyze resume")

    # AI feedback and tips are already included in result from analyze_resume_backend
    return result


# ---------------- Get Resume Analysis Result ---------------- 
# Note: This route must be defined before any /resume/{user_id} routes
# to avoid path parameter conflicts
@router.get("/result", name="get_resume_result")
def get_result(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    rule = db.query(ResumeRules).filter(
        ResumeRules.user_id == current_user.user_id
    ).order_by(ResumeRules.created_at.desc()).first()

    # If ResumeRules doesn't exist, check if user has resume in users table
    if not rule:
        # Check if user has resume_blob in users table
        user = db.query(User).filter(User.user_id == current_user.user_id).first()
        if user and user.resume_blob:
            # Create ResumeRules entry from users.resume_blob
            rule = ResumeRules(
                user_id=user.user_id,
                resume_blob=user.resume_blob,
                resume_url=user.resume_url or "resume.pdf",
                analysis_status="pending"
            )
            db.add(rule)
            db.commit()
            db.refresh(rule)
        else:
            raise HTTPException(status_code=404, detail="User has not uploaded a resume")

    if rule.analysis_status != "completed":
        # Check if user has completed quiz (has best_domain)
        best_attempt = (
            db.query(UserQuizAttempts)
            .filter(UserQuizAttempts.user_id == current_user.user_id)
            .order_by(UserQuizAttempts.taken_on.desc())
            .first()
        )
        
        # If user has completed quiz, trigger analysis automatically
        if best_attempt and best_attempt.best_domain and rule.resume_blob:
            try:
                result = analyze_resume_backend(rule.rule_id, db)
                if result:
                    # Analysis completed, refresh rule to get updated status
                    db.refresh(rule)
                    # If still not completed, return pending
                    if rule.analysis_status != "completed":
                        return {"status": "pending", "message": "Resume uploaded, analysis in progress..."}
                    # Otherwise continue to return results below
                else:
                    return {"status": "pending", "message": "Resume uploaded, analysis in progress..."}
            except Exception as e:
                print(f"Error auto-analyzing resume: {e}")
                return {"status": "pending", "message": "Resume uploaded, analysis not done yet"}
        else:
            return {"status": "pending", "message": "Resume uploaded, analysis will start after quiz completion"}

    # Re-analyze to get full analysis data for AI feedback generation
    # We need the full analysis result, not just stored fields
    # Get domain skills for re-analysis
    best_attempt = (
        db.query(UserQuizAttempts)
        .filter(UserQuizAttempts.user_id == current_user.user_id)
        .order_by(UserQuizAttempts.taken_on.desc())
        .first()
    )
    domain = rule.domain or (best_attempt.best_domain if best_attempt and best_attempt.best_domain else "software_development")
    
    skill_rows = db.query(Skills).filter(Skills.domain == domain).all()
    domain_skill_list = []
    for r in skill_rows:
        if r.description:
            domain_skill_list.extend([s.strip() for s in r.description.split(",") if s.strip()])
        else:
            domain_skill_list.append(r.skill_name)
    domain_skill_list = list(dict.fromkeys(domain_skill_list))
    
    # Re-analyze to get full results
    if rule.resume_blob:
        analysis_result = analyze_ats(rule.resume_blob, domain_skill_list)
        ai_feedback_data = generate_ai_feedback(analysis_result, domain)
        
        # Handle matched and missing skills - ensure they're lists
        matched_skills_list = []
        missing_skills_list = []
        
        if rule.matched_skills:
            if isinstance(rule.matched_skills, str):
                matched_skills_list = [s.strip() for s in rule.matched_skills.split(",") if s.strip()]
            elif isinstance(rule.matched_skills, list):
                matched_skills_list = [str(s) for s in rule.matched_skills if s]
        elif analysis_result.get("matched_skills"):
            matched_skills_list = analysis_result.get("matched_skills", [])
            if isinstance(matched_skills_list, str):
                matched_skills_list = [s.strip() for s in matched_skills_list.split(",") if s.strip()]
        
        if rule.missing_skills:
            if isinstance(rule.missing_skills, str):
                missing_skills_list = [s.strip() for s in rule.missing_skills.split(",") if s.strip()]
            elif isinstance(rule.missing_skills, list):
                missing_skills_list = [str(s) for s in rule.missing_skills if s]
        elif analysis_result.get("missing_skills"):
            missing_skills_list = analysis_result.get("missing_skills", [])
            if isinstance(missing_skills_list, str):
                missing_skills_list = [s.strip() for s in missing_skills_list.split(",") if s.strip()]
        
        return {
            "score": rule.score or analysis_result.get("ats_score", 0),
            "domain": domain,
            "matched_skills": matched_skills_list,
            "missing_skills": missing_skills_list,
            "ai_feedback": ai_feedback_data.get("feedback", ""),
            "tips": ai_feedback_data.get("tips", [])
        }
    else:
        # Fallback if resume blob is missing
        matched_skills_list = []
        missing_skills_list = []
        
        if rule.matched_skills:
            if isinstance(rule.matched_skills, str):
                matched_skills_list = [s.strip() for s in rule.matched_skills.split(",") if s.strip()]
            elif isinstance(rule.matched_skills, list):
                matched_skills_list = [str(s) for s in rule.matched_skills if s]
        
        if rule.missing_skills:
            if isinstance(rule.missing_skills, str):
                missing_skills_list = [s.strip() for s in rule.missing_skills.split(",") if s.strip()]
            elif isinstance(rule.missing_skills, list):
                missing_skills_list = [str(s) for s in rule.missing_skills if s]
        
        return {
            "score": rule.score or 0,
            "domain": domain,
            "matched_skills": matched_skills_list,
            "missing_skills": missing_skills_list,
            "ai_feedback": "Resume analysis data is incomplete. Please re-upload your resume.",
            "tips": ["Upload your resume again to get detailed feedback", "Ensure your resume is in PDF format", "Include all relevant sections"]
        }


# ---------------- Download Resume ----------------
@router.get("/download")
def download_resume(
    user_id: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Download resume:
    - If `user_id` query param is not provided: download current user's resume
    - If `user_id` is provided as a query param: download that user's resume
    """
    uid = user_id or current_user.user_id
    user = db.query(User).filter(User.user_id == uid).first()

    if not user:
        raise HTTPException(status_code=404, detail=f"User '{uid}' not found")

    if not user.resume_blob:
        raise HTTPException(status_code=404, detail=f"Resume for user '{uid}' not uploaded")

    return StreamingResponse(
        BytesIO(user.resume_blob),
        media_type="application/pdf",
        headers={"Content-Disposition": f"inline; filename={user.resume_url}"}
    )
