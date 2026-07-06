from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import UserQuizAttempts, AITasks, RoadmapTimeline, User

router = APIRouter(
    prefix="/roadmap",
    tags=["Roadmap"]
)

@router.get("/{user_id}")
def get_roadmap_timeline(user_id: str, db: Session = Depends(get_db)):
    """
    Get roadmap timeline based on completed AI tasks.
    Displays learning process with 3 levels:
    - Level I: User status, covered areas, areas to learn/improve
    - Level II: Task progress based on AI task page
    - Level III: Job opportunities (intern, trainee) worldwide
    """
    # Get user data
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Get quiz results
    attempt = (
        db.query(UserQuizAttempts)
        .filter(UserQuizAttempts.user_id == user_id)
        .order_by(UserQuizAttempts.taken_on.desc())
        .first()
    )

    if not attempt:
        raise HTTPException(status_code=404, detail="No quiz attempt found. Please complete the quiz first.")

    best_domain = attempt.best_domain or "General"
    score = attempt.score or 0

    # Level I: Get covered areas and areas to improve from domain scores
    domain_field_map = {
        "ai_data_science": "AI & Data Science",
        "data_analytics": "Data Analytics",
        "it_management": "IT Management",
        "database": "Database",
        "cloud_devops": "Cloud & DevOps",
        "software_development": "Software Development",
        "networking": "Networking",
        "mobile_development": "Mobile Development",
        "design": "Design",
        "cybersecurity": "Cybersecurity",
        "web_development": "Web Development",
    }
    
    covered_areas = []
    areas_to_improve = []
    
    for field, domain_name in domain_field_map.items():
        domain_score = getattr(attempt, field, 0) or 0
        if domain_score >= 40:
            covered_areas.append({
                "domain": domain_name,
                "score": domain_score,
                "level": "high" if domain_score >= 70 else "medium"
            })
        elif domain_score < 30 and domain_name != best_domain:
            areas_to_improve.append({
                "domain": domain_name,
                "score": domain_score,
                "level": "beginner"
            })
    
    # Sort covered areas by score (highest first) and areas to improve by score (lowest first)
    covered_areas.sort(key=lambda x: x["score"], reverse=True)
    areas_to_improve.sort(key=lambda x: x["score"])
    
    # Limit to top 5 for each
    covered_areas = covered_areas[:5]
    areas_to_improve = areas_to_improve[:5]

    # Determine user status
    if score >= 70:
        user_status = "Advanced Learner"
    elif score >= 40:
        user_status = "Active Learner"
    else:
        user_status = "Getting Started"

    # Level II: Get task progress from AI tasks
    from models import TaskStatusEnum
    all_tasks = db.query(AITasks).filter(AITasks.user_id == user_id).all()
    completed_tasks = [t for t in all_tasks if t.status == TaskStatusEnum.completed]
    pending_tasks = [t for t in all_tasks if t.status == TaskStatusEnum.pending]
    # Note: TaskStatusEnum only has 'pending' and 'completed', no 'in_progress'
    # Tasks that are started but not completed are still considered 'pending'
    
    total_tasks = len(all_tasks)
    task_progress = (len(completed_tasks) / total_tasks * 100) if total_tasks > 0 else 0
    
    task_details = []
    for task in all_tasks:
        task_details.append({
            "task_id": task.task_id,
            "task_name": task.task_name,
            "status": task.status.value,
            "created_at": task.created_at.isoformat() if task.created_at else None,
            "due_date": task.due_date.isoformat() if task.due_date else None
        })

    # Level III: Generate job opportunities (only show if tasks are completed)
    job_opportunities = []
    if len(completed_tasks) >= 2:
        # Generate worldwide job opportunities based on domain
        job_opportunities = _generate_job_opportunities(best_domain)

    # Determine level completion status
    level_i_status = "completed" if score >= 40 and len(covered_areas) >= 3 else ("in_progress" if score > 0 else "pending")
    level_ii_status = "completed" if len(completed_tasks) >= 2 else ("in_progress" if len(completed_tasks) > 0 else "pending")
    level_iii_status = "available" if len(completed_tasks) >= 2 else "locked"

    return {
        "best_domain": best_domain,
        "quiz_score": score,
        "levels": {
            "level_i": {
                "status": level_i_status,
                "user_status": user_status,
                "covered_areas": covered_areas,
                "areas_to_improve": areas_to_improve,
                "progress": min(score, 100)
            },
            "level_ii": {
                "status": level_ii_status,
                "total_tasks": total_tasks,
                "completed_tasks": len(completed_tasks),
                "pending_tasks": len(pending_tasks),
                "task_progress_percentage": round(task_progress, 1),
                "task_details": task_details
            },
            "level_iii": {
                "status": level_iii_status,
                "job_opportunities": job_opportunities,
                "message": "Complete at least 2 AI tasks to unlock job opportunities" if len(completed_tasks) < 2 else f"Great! {len(completed_tasks)} tasks completed. Explore opportunities below!"
            }
        }
    }

def _generate_job_opportunities(domain: str) -> list:
    """Generate worldwide job opportunities for interns and trainees based on domain."""
    domain_opportunities_map = {
        "Design": [
            {"position": "UI/UX Design Intern", "company": "Tech Companies Worldwide", "location": "Remote/On-site", "type": "Intern"},
            {"position": "Graphic Design Trainee", "company": "Creative Agencies", "location": "Global", "type": "Trainee"},
            {"position": "Product Design Intern", "company": "Startups & Tech Firms", "location": "Remote", "type": "Intern"},
        ],
        "Web Development": [
            {"position": "Frontend Developer Intern", "company": "Web Agencies", "location": "Remote", "type": "Intern"},
            {"position": "Full Stack Developer Trainee", "company": "Tech Startups", "location": "Global", "type": "Trainee"},
            {"position": "Web Development Intern", "company": "Software Companies", "location": "Remote/On-site", "type": "Intern"},
        ],
        "AI & Data Science": [
            {"position": "AI/ML Intern", "company": "Tech Giants & Startups", "location": "Remote", "type": "Intern"},
            {"position": "Data Science Trainee", "company": "Analytics Companies", "location": "Global", "type": "Trainee"},
            {"position": "Machine Learning Intern", "company": "AI Companies", "location": "Remote", "type": "Intern"},
        ],
        "IT Management": [
            {"position": "IT Project Management Intern", "company": "Corporations", "location": "On-site", "type": "Intern"},
            {"position": "Business Analyst Trainee", "company": "Consulting Firms", "location": "Global", "type": "Trainee"},
            {"position": "IT Support Intern", "company": "Tech Companies", "location": "Remote/On-site", "type": "Intern"},
        ],
        "Software Development": [
            {"position": "Software Engineer Intern", "company": "Tech Companies", "location": "Remote/On-site", "type": "Intern"},
            {"position": "Developer Trainee", "company": "Software Firms", "location": "Global", "type": "Trainee"},
            {"position": "Junior Developer Intern", "company": "Startups", "location": "Remote", "type": "Intern"},
        ],
        "Mobile Development": [
            {"position": "Mobile App Developer Intern", "company": "App Development Companies", "location": "Remote", "type": "Intern"},
            {"position": "iOS/Android Trainee", "company": "Mobile Tech Firms", "location": "Global", "type": "Trainee"},
        ],
        "Data Analytics": [
            {"position": "Data Analyst Intern", "company": "Analytics Companies", "location": "Remote", "type": "Intern"},
            {"position": "Business Intelligence Trainee", "company": "Corporations", "location": "Global", "type": "Trainee"},
        ],
        "Cybersecurity": [
            {"position": "Cybersecurity Intern", "company": "Security Firms", "location": "Remote/On-site", "type": "Intern"},
            {"position": "Security Analyst Trainee", "company": "Tech Companies", "location": "Global", "type": "Trainee"},
        ],
        "Cloud & DevOps": [
            {"position": "DevOps Engineer Intern", "company": "Cloud Companies", "location": "Remote", "type": "Intern"},
            {"position": "Cloud Solutions Trainee", "company": "Tech Firms", "location": "Global", "type": "Trainee"},
        ],
        "Database": [
            {"position": "Database Administrator Intern", "company": "Tech Companies", "location": "Remote/On-site", "type": "Intern"},
            {"position": "Database Developer Trainee", "company": "Software Firms", "location": "Global", "type": "Trainee"},
        ],
        "Networking": [
            {"position": "Network Engineer Intern", "company": "IT Companies", "location": "On-site", "type": "Intern"},
            {"position": "Network Administrator Trainee", "company": "Corporations", "location": "Global", "type": "Trainee"},
        ],
    }
    
    # Get opportunities for the domain, with a default set
    opportunities = domain_opportunities_map.get(domain, [
        {"position": f"{domain} Intern", "company": "Tech Companies", "location": "Remote/On-site", "type": "Intern"},
        {"position": f"{domain} Trainee", "company": "Industry Leaders", "location": "Global", "type": "Trainee"},
    ])
    
    # Add common remote opportunities
    opportunities.extend([
        {"position": "Remote Tech Intern", "company": "Global Tech Companies", "location": "Remote - Worldwide", "type": "Intern"},
        {"position": "Entry-Level Tech Trainee", "company": "International Firms", "location": "Remote", "type": "Trainee"},
    ])
    
    return opportunities[:5]  # Return top 5 opportunities

