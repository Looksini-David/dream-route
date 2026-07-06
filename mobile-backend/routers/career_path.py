from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import UserQuizAttempts, CareerPaths, Skills, IndustryData, Quizzes, User
from services.market_trends import generate_daily_market_trends

router = APIRouter(
    prefix="/career-path",
    tags=["Career Path"]
)

@router.get("/{user_id}")
def get_career_path(user_id: str, db: Session = Depends(get_db)):
    """
    Get AI-driven career path based on user's best domain:
    - Job roles from domain titles
    - Required skills & tools
    - Roadmap suggestions (courses, projects, certificates)
    - Market trends (salary range, demand level)
    """
    # Get latest quiz attempt for the user
    attempt = (
        db.query(UserQuizAttempts)
        .filter(UserQuizAttempts.user_id == user_id)
        .order_by(UserQuizAttempts.taken_on.desc())
        .first()
    )

    if not attempt or not attempt.best_domain:
        raise HTTPException(status_code=404, detail="No quiz result found for user")

    best_domain = attempt.best_domain

    # Get job roles (titles) for this domain
    titles_query = db.query(Quizzes.title).filter(Quizzes.domain == best_domain).all()
    job_roles = [t[0] for t in titles_query if t[0]]

    # Get required skills & tools for this domain
    skills_query = db.query(Skills).filter(Skills.domain == best_domain).all()
    required_skills = []
    tools = []
    
    for skill in skills_query:
        if skill.skill_name:
            required_skills.append(skill.skill_name)
        if skill.description:
            # Extract tools from description if available
            desc_lower = skill.description.lower()
            if any(tool in desc_lower for tool in ['figma', 'adobe', 'sketch', 'invision', 'xd']):
                tools.extend([t.strip() for t in skill.description.split(',') if t.strip()])

    # Get career path data with roadmap suggestions
    career_paths = db.query(CareerPaths).filter(CareerPaths.domain == best_domain).all()
    roadmap_suggestions = {
        "courses": [],
        "projects": [],
        "certificates": []
    }

    if career_paths:
        for cp in career_paths:
            if cp.roadmap_suggestion:
                # Parse roadmap suggestions (assuming structured format)
                roadmap_suggestions["courses"].extend([
                    line.strip() for line in cp.roadmap_suggestion.split('\n') 
                    if 'course' in line.lower() or 'learn' in line.lower()
                ])
                roadmap_suggestions["projects"].extend([
                    line.strip() for line in cp.roadmap_suggestion.split('\n') 
                    if 'project' in line.lower() or 'build' in line.lower()
                ])
                roadmap_suggestions["certificates"].extend([
                    line.strip() for line in cp.roadmap_suggestion.split('\n') 
                    if 'certificate' in line.lower() or 'certification' in line.lower()
                ])

    # Default roadmap suggestions if none found
    if not roadmap_suggestions["courses"]:
        roadmap_suggestions["courses"] = [
            f"Complete {best_domain} Fundamentals Course",
            f"Advanced {best_domain} Masterclass"
        ]
    if not roadmap_suggestions["projects"]:
        roadmap_suggestions["projects"] = [
            f"Build a {best_domain} portfolio project",
            f"Create a real-world {best_domain} application"
        ]
    if not roadmap_suggestions["certificates"]:
        roadmap_suggestions["certificates"] = [
            f"{best_domain} Professional Certification",
            f"{best_domain} Industry Standard Certificate"
        ]

    # Generate AI-powered daily market trends for this specific domain
    # Get both Global and Sri Lanka (Local) market trends
    global_trends = generate_daily_market_trends(best_domain, "global")
    sri_lanka_trends = generate_daily_market_trends(best_domain, "sri_lanka")

    # Get required tools from career paths
    all_tools = set()
    for cp in career_paths:
        if cp.tools:
            all_tools.update([t.strip() for t in cp.tools.split(',') if t.strip()])
    
    # Add common tools based on domain
    domain_tools_map = {
        "Design": ["Figma", "Adobe XD", "Sketch", "InVision", "Photoshop", "Illustrator"],
        "Web Development": ["VS Code", "Git", "Chrome DevTools", "React", "Node.js"],
        "AI & Data Science": ["Python", "Jupyter", "TensorFlow", "PyTorch", "Pandas"],
        "Mobile Development": ["Android Studio", "Xcode", "Flutter", "React Native"],
    }
    
    if best_domain in domain_tools_map:
        all_tools.update(domain_tools_map[best_domain])

    return {
        "best_domain": best_domain,
        "job_roles": job_roles if job_roles else [best_domain + " Specialist"],
        "required_skills": list(set(required_skills))[:10],  # Top 10 unique skills
        "required_tools": list(all_tools)[:10],  # Top 10 tools
        "roadmap_suggestions": roadmap_suggestions,
        "market_trends": {
            "global": {
                "salary_range": global_trends["salary_range"],
                "salary_min": global_trends.get("salary_min"),
                "salary_max": global_trends.get("salary_max"),
                "demand_level": global_trends["demand_level"],
                "demand_percentage": global_trends.get("demand_percentage", 75),
                "insights": global_trends.get("insights", ""),
                "currency": global_trends.get("currency", "USD"),
            },
            "sri_lanka": {
                "salary_range": sri_lanka_trends["salary_range"],
                "salary_min": sri_lanka_trends.get("salary_min"),
                "salary_max": sri_lanka_trends.get("salary_max"),
                "demand_level": sri_lanka_trends["demand_level"],
                "demand_percentage": sri_lanka_trends.get("demand_percentage", 75),
                "insights": sri_lanka_trends.get("insights", ""),
                "currency": sri_lanka_trends.get("currency", "LKR"),
            },
            "last_updated": global_trends.get("last_updated", "")
        }
    }

