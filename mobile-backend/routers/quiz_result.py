from fastapi import APIRouter, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import UserQuizAttempts, Quizzes, CareerPaths  # Import your SQLAlchemy models
from fastapi import Depends

router = APIRouter(
    prefix="/quiz-result",
    tags=["Quiz Result"]
)


@router.get("/{user_id}")
def get_quiz_result(user_id: str, db: Session = Depends(get_db)):
    """
    Fetch quiz result for a user and return:
    - score
    - best domain
    - domain scores
    - best domain details (description + titles)
    """

    # Get latest quiz attempt for the user
    attempt = (
        db.query(UserQuizAttempts)
        .filter(UserQuizAttempts.user_id == user_id)
        .order_by(UserQuizAttempts.taken_on.desc())
        .first()
    )

    if not attempt:
        raise HTTPException(status_code=404, detail="Quiz attempt not found")

    # List of all domains as in quizzes table
    all_domains = [
        "AI & Data Science",
        "Data Analytics",
        "IT Management",
        "Database",
        "Cloud & DevOps",
        "Software Development",
        "Networking",
        "Mobile Development",
        "Design",
        "Cybersecurity",
        "Web Development",
    ]

    # Map backend field names to display names
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

    # Get domain scores, levels, and titles (roles) for all 11 domains
    domain_scores = []
    for field, display in domain_field_map.items():
        score = getattr(attempt, field, 0)
        # Determine level based on score (customize as needed)
        if score >= 70:
            level = "high"
        elif score >= 40:
            level = "medium"
        else:
            level = "beginner"
        # Fetch all titles (roles) for this domain from quizzes table
        titles_query = db.query(Quizzes.title).filter(Quizzes.domain == display).all()
        titles_list = [t[0] for t in titles_query]
        domain_scores.append({
            "domain": display,
            "score": score,
            "level": level,
            "titles": titles_list
        })


    # Get best domain details
    best_domain = attempt.best_domain

    # Fetch titles and description from quizzes table
    titles_query = (
        db.query(Quizzes.title)
        .filter(Quizzes.domain == best_domain)
        .all()
    )
    titles_list = [{"title": t[0], "desc": ""} for t in titles_query]  # Add description if available

    # Fetch recommended roles from CareerPaths table
    recommended_roles_query = (
        db.query(CareerPaths.role_name)
        .filter(CareerPaths.domain == best_domain)
        .all()
    )
    recommended_roles = [r[0] for r in recommended_roles_query]

    # Optional: static descriptions for domains
    domain_descriptions = {
        "Design": "Design focuses on creating visually appealing and user-friendly solutions.",
        "Web Development": "Web Development involves building dynamic and responsive websites using modern technologies.",
        "Mobile Development": "Mobile development focuses on creating smooth and functional mobile apps.",
        "Software Development": "Software development focuses on planning, coding, testing, and maintaining applications.",
        "Database": "Database professionals manage, organize, and secure structured information.",
        "Networking": "Networking focuses on maintaining connectivity and communication between systems.",
        "Cybersecurity": "Cybersecurity protects systems from threats through monitoring and defense strategies.",
        "Data Analytics": "Data Analytics involves extracting insights from datasets for decision-making.",
        "AI & Data Science": "AI and Data Science focus on machine intelligence, predictions, and data-driven decision-making.",
        "Cloud & DevOps": "Cloud & DevOps ensure reliable deployment, automation, and cloud resource management.",
        "IT Management": "IT Management coordinates technology teams, projects, and business goals.",
    }

    # Find the best domain's titles (roles) from the domain_scores list
    best_domain_titles = []
    for d in domain_scores:
        if d["domain"] == best_domain:
            best_domain_titles = d["titles"]
            break

    response = {
        "score": attempt.score,
        "best_domain": best_domain,
        "best_domain_details": {
            "description": domain_descriptions.get(best_domain, ""),
            "titles": best_domain_titles,
        },
        "recommended_roles": recommended_roles,
        "domains": domain_scores,
    }

    return response
