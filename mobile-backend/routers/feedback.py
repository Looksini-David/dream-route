from fastapi import APIRouter, HTTPException, Depends, Body
from sqlalchemy.orm import Session
from database import get_db
from models import UserQuizAttempts, AITasks, User, Feedback as FeedbackModel, CareerPaths, Skills, Quizzes
from datetime import datetime
from pydantic import BaseModel
from typing import Optional
import random

router = APIRouter(
    prefix="/feedback",
    tags=["Feedback"]
)

class UserFeedbackRequest(BaseModel):
    content: str

def _generate_feedback_id(db: Session) -> str:
    """Generate a unique feedback_id in format F####."""
    max_attempts = 100
    for _ in range(max_attempts):
        # Generate F followed by 4 digits (e.g., F0001, F0027, F9999)
        feedback_num = random.randint(1, 9999)
        feedback_id = f"F{feedback_num:04d}"
        
        # Check if ID already exists
        existing = db.query(FeedbackModel).filter(FeedbackModel.feedback_id == feedback_id).first()
        if not existing:
            return feedback_id
    
    # Fallback: use timestamp-based ID if all attempts fail
    timestamp = int(datetime.now().timestamp())
    return f"F{timestamp % 100000:05d}"

@router.get("/{user_id}")
def get_ai_feedback(user_id: str, db: Session = Depends(get_db)):
    """
    Get AI-generated motivational and funny feedback based on user performance.
    Returns Level I (Status/Covered/Improve), Level II (Task Progress), Level III (Job Opportunities).
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
        raise HTTPException(status_code=404, detail="No quiz attempt found")

    # Get task progress
    tasks = db.query(AITasks).filter(AITasks.user_id == user_id).all()
    completed_tasks = [t for t in tasks if t.status.value == "completed"]
    task_progress = len(completed_tasks) / len(tasks) * 100 if tasks else 0

    # Generate AI feedback
    score = attempt.score or 0
    best_domain = attempt.best_domain or "General"
    readiness_level = attempt.readiness_level or "beginner"
    
    # Determine performance level
    performance_level = "excellent" if score >= 70 else "good" if score >= 50 else "average" if score >= 40 else "below_average"
    
    # Comprehensive AI Performance Analysis
    performance_analysis = _analyze_performance(attempt, score, best_domain, task_progress, len(completed_tasks), len(tasks))
    
    # Motivational and funny feedback based on score
    motivational_feedback = _generate_motivational_feedback(score, best_domain, performance_level)
    
    # Show funny feedback for average or below average performance
    funny_feedback = None
    if performance_level in ["average", "below_average"]:
        funny_feedback = _generate_funny_feedback(score, best_domain, performance_level)
    
    # Get career path suggestions
    career_path_data = _get_career_path_suggestions(db, best_domain)

    # Level I: Status, Covered Area, Need to Learn/Improve
    level_i = {
        "status": "Active Learner" if score >= 40 else "Getting Started",
        "covered_areas": _get_covered_areas(attempt, best_domain),
        "need_to_learn": _get_improvement_areas(attempt, best_domain)
    }

    # Level II: Task Progress based on AI Task page
    level_ii = {
        "total_tasks": len(tasks),
        "completed_tasks": len(completed_tasks),
        "progress_percentage": task_progress,
        "task_details": [
            {
                "task_name": t.task_name,
                "status": t.status.value,
                "completed_at": t.created_at.isoformat() if t.status.value == "completed" and t.created_at else None
            }
            for t in tasks
        ]
    }

    # Level III: Job Opportunities (intern, trainee, etc.)
    level_iii = {
        "recommended_roles": career_path_data.get("job_roles", []),
        "suggested_platforms": [
            "LinkedIn",
            "Indeed",
            "Glassdoor",
            "Internshala",
            "AngelList"
        ],
        "tips": [
            f"Search for '{best_domain} intern' positions",
            "Apply to startups for more opportunities",
            "Build portfolio projects to showcase skills",
            f"Network on LinkedIn with {best_domain} professionals"
        ]
    }

    # Save feedback to database (optional - only if you want to store AI feedback)
    # Generate unique feedback_id
    feedback_id = _generate_feedback_id(db)
    feedback_content = f"""Motivational: {motivational_feedback}\n\nFunny: {funny_feedback}\n\nLevel I: {level_i}\nLevel II: {level_ii}\nLevel III: {level_iii}"""
    new_feedback = FeedbackModel(
        feedback_id=feedback_id,
        user_id=user_id,
        source="AI",
        content=feedback_content
    )
    db.add(new_feedback)
    db.commit()

    return {
        "user_name": user.name,
        "best_domain": best_domain,
        "quiz_score": score,
        "readiness_level": readiness_level,
        "performance_level": performance_level,
        "performance_analysis": performance_analysis,
        "motivational_feedback": motivational_feedback,
        "funny_feedback": funny_feedback,
        "career_path_suggestion": {
            "message": f"Based on your performance, we recommend focusing on {best_domain} career path!",
            "job_roles": career_path_data.get("job_roles", []),
            "required_skills": career_path_data.get("required_skills", []),
            "required_tools": career_path_data.get("required_tools", []),
            "market_trends": career_path_data.get("market_trends", {})
        },
        "level_i": level_i,
        "level_ii": level_ii,
        "level_iii": level_iii
    }

def _generate_motivational_feedback(score: int, domain: str, performance_level: str) -> str:
    """Generate comprehensive motivational feedback based on performance."""
    motivational_templates = {
        "excellent": [
            f"🌟 Outstanding Performance! You've scored {score}% and demonstrated exceptional strength in {domain}! You're clearly on the path to becoming an expert. Your dedication is paying off - keep pushing forward and challenging yourself with advanced concepts!",
            f"🎯 Exceptional Results! With {score}% in {domain}, you're showing mastery-level understanding. You're not just learning - you're excelling! Continue building on this strong foundation and explore advanced topics to reach the next level.",
            f"💎 Top Performer! Your {score}% score in {domain} shows you have a deep understanding of the field. You're ready to tackle real-world projects and mentor others. Keep up the excellent work!"
        ],
        "good": [
            f"💪 Great Job! You've scored {score}% in {domain}, showing a solid foundation. You're making excellent progress! With consistent practice and dedication, you'll master this field in no time. Every expert was once a beginner - you're well on your way!",
            f"🚀 Strong Performance! Your {score}% score demonstrates good understanding of {domain}. You're building momentum! Keep practicing, stay curious, and don't hesitate to explore more challenging projects. You've got this!",
            f"⭐ Well Done! With {score}% in {domain}, you're showing real potential. You understand the fundamentals well. Now is the perfect time to dive deeper, work on projects, and build your portfolio. Keep going!"
        ],
        "average": [
            f"📚 Steady Progress! You've scored {score}% in {domain}. You're building your foundation, and that's exactly where great careers start! Every small step counts. Focus on consistent practice, review the basics, and gradually tackle more complex topics. Progress over perfection!",
            f"🌱 Growing Strong! Your {score}% score shows you're learning and growing in {domain}. This is your learning journey - embrace it! Take time to review concepts, practice regularly, and don't be afraid to ask questions. You're building something great!",
            f"🎓 Learning Journey! With {score}% in {domain}, you're on the right track. Remember, every expert started exactly where you are now. Focus on understanding fundamentals, practice regularly, and celebrate small wins. You're making progress!"
        ],
        "below_average": [
            f"🚀 Starting Your Journey! You've scored {score}% in {domain}, and that's perfectly okay! Every expert was once a beginner. This is your starting point, and it's full of potential. Take it one step at a time, practice regularly, and don't give up. Your future self will thank you!",
            f"💫 New Beginnings! Your {score}% score in {domain} is just the beginning of an exciting learning adventure! Every small improvement is a victory. Focus on the basics, practice consistently, and remember - progress, not perfection, is the goal. You've got this!",
            f"🌟 Growth Mindset! With {score}% in {domain}, you're at the start of something amazing! Learning is a journey, not a destination. Take your time, practice regularly, ask for help when needed, and celebrate every step forward. You're building your future!"
        ]
    }
    
    import random
    return random.choice(motivational_templates[performance_level])

def _generate_funny_feedback(score: int, domain: str, performance_level: str) -> str:
    """Generate funny and motivational feedback for average/below average performance."""
    funny_messages = {
        "average": [
            f"🎭 Score: {score}%? You're like a {domain} actor in the first act - the plot is just getting interesting! Your character arc is about to get EPIC! 🎬",
            f"🎪 Welcome to the {domain} circus! You're learning to juggle concepts, and that's totally normal! Soon you'll be the ringmaster of your own career show! 🎩",
            f"🍕 You're like a {domain} pizza - still in the oven, but getting better every minute! {score}% is just the beginning of your delicious journey! 🧀",
            f"🎮 Level {score}% unlocked in {domain}! You're in the tutorial phase, and that's where all the fun begins! Time to level up! ⬆️",
            f"🌊 You're riding the {domain} learning wave! {score}% means you're catching the wave - soon you'll be surfing like a pro! 🏄"
        ],
        "below_average": [
            f"🦸 Score: {score}%? Hey, even superheroes start with awkward first steps! Your {domain} origin story is just beginning - and origin stories are always the best part! 💥",
            f"🌱 You're like a {domain} seedling that's about to grow into a mighty career tree! Water it with practice, sunshine it with curiosity, and watch yourself grow! 🌳",
            f"🎯 You're in the {domain} training montage phase! Picture yourself in slow motion, getting stronger with each practice session! Soon you'll be the hero of your own career story! 🦸",
            f"🚀 {score}%? That's your launch pad, not your destination! You're like a rocket that's just ignited - the best part is yet to come! 🌟",
            f"🎨 You're painting your {domain} masterpiece, and {score}% is just the first brushstroke! Every great artist starts with a blank canvas. Keep painting! 🖌️",
            f"🎪 Welcome to the {domain} learning adventure! {score}% is your starting point, and every adventure needs a beginning! Your epic journey starts now! 🗺️"
        ]
    }
    
    import random
    return random.choice(funny_messages[performance_level])

def _get_covered_areas(attempt, domain: str) -> list:
    """Get areas covered based on quiz attempt."""
    covered = [domain]
    
    # Add covered domains based on scores
    if attempt.ai_data_science and attempt.ai_data_science > 30:
        covered.append("AI & Data Science")
    if attempt.web_development and attempt.web_development > 30:
        covered.append("Web Development")
    if attempt.design and attempt.design > 30:
        covered.append("Design")
    
    return covered

def _get_improvement_areas(attempt, domain: str) -> list:
    """Get areas that need improvement."""
    improve = []
    
    # Suggest improvement areas based on low scores
    if attempt.ai_data_science and attempt.ai_data_science < 40:
        improve.append("AI & Data Science fundamentals")
    if attempt.web_development and attempt.web_development < 40:
        improve.append("Web Development basics")
    if attempt.design and attempt.design < 40:
        improve.append("Design principles")
    
    # Always suggest improving best domain
    improve.append(f"Advanced {domain} concepts")
    
    return improve if improve else [f"{domain} fundamentals", "Practice projects"]

def _analyze_performance(attempt, score: int, domain: str, task_progress: float, completed_tasks: int, total_tasks: int) -> dict:
    """Comprehensive AI analysis of user performance."""
    # Analyze domain scores
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
    
    strengths = []
    weaknesses = []
    domain_scores = []
    
    for field, domain_name in domain_field_map.items():
        domain_score = getattr(attempt, field, 0) or 0
        domain_scores.append({"domain": domain_name, "score": domain_score})
        
        if domain_score >= 60:
            strengths.append({"domain": domain_name, "score": domain_score, "level": "strong"})
        elif domain_score < 30:
            weaknesses.append({"domain": domain_name, "score": domain_score, "level": "needs_improvement"})
    
    # Sort by score
    strengths.sort(key=lambda x: x["score"], reverse=True)
    weaknesses.sort(key=lambda x: x["score"])
    
    # Overall assessment
    if score >= 70:
        overall_assessment = "Excellent - You demonstrate strong understanding and are ready for advanced challenges."
    elif score >= 50:
        overall_assessment = "Good - You have a solid foundation and are making steady progress."
    elif score >= 40:
        overall_assessment = "Average - You're building your foundation. Focus on consistent practice and review."
    else:
        overall_assessment = "Below Average - You're at the beginning of your journey. Focus on fundamentals and don't give up!"
    
    # Task completion analysis
    task_analysis = ""
    if total_tasks > 0:
        if task_progress >= 80:
            task_analysis = "Excellent task completion rate! You're very consistent with your practice."
        elif task_progress >= 50:
            task_analysis = "Good progress on tasks! Keep up the momentum."
        elif task_progress > 0:
            task_analysis = "You've started working on tasks - that's great! Try to complete more to accelerate your learning."
        else:
            task_analysis = "Start working on AI tasks to practice and improve your skills in your recommended domain."
    else:
        task_analysis = "No tasks yet. Complete AI tasks to practice and track your progress."
    
    return {
        "overall_score": score,
        "overall_assessment": overall_assessment,
        "strengths": strengths[:3],  # Top 3 strengths
        "weaknesses": weaknesses[:3],  # Top 3 areas to improve
        "task_analysis": task_analysis,
        "task_completion_rate": round(task_progress, 1),
        "recommendations": _generate_recommendations(score, domain, task_progress, strengths, weaknesses)
    }

def _generate_recommendations(score: int, domain: str, task_progress: float, strengths: list, weaknesses: list) -> list:
    """Generate personalized recommendations based on performance."""
    recommendations = []
    
    if score < 40:
        recommendations.append(f"Focus on {domain} fundamentals - review basic concepts and practice regularly")
        recommendations.append("Complete beginner-level projects to build confidence")
        recommendations.append("Take time to understand concepts before moving to advanced topics")
    elif score < 70:
        recommendations.append(f"Continue building on your {domain} foundation with intermediate projects")
        recommendations.append("Practice regularly to reinforce your learning")
        recommendations.append("Explore real-world applications of {domain} concepts")
    else:
        recommendations.append(f"Challenge yourself with advanced {domain} projects and concepts")
        recommendations.append("Consider mentoring others or contributing to open-source projects")
        recommendations.append("Build a comprehensive portfolio showcasing your {domain} expertise")
    
    if task_progress < 50:
        recommendations.append("Complete more AI tasks to practice and improve your skills")
    
    if weaknesses:
        weak_domains = [w["domain"] for w in weaknesses[:2]]
        recommendations.append(f"Review and practice: {', '.join(weak_domains)}")
    
    return recommendations[:5]  # Top 5 recommendations

def _get_career_path_suggestions(db: Session, domain: str) -> dict:
    """Get career path suggestions with job roles, skills, and tools."""
    try:
        # Get job roles
        titles_query = db.query(Quizzes.title).filter(Quizzes.domain == domain).distinct().all()
        job_roles = [t[0] for t in titles_query if t[0] and t[0].strip()]
        
        # Get roles from CareerPaths
        career_path_roles = db.query(CareerPaths.role_name).filter(CareerPaths.domain == domain).distinct().all()
        career_roles = [r[0] for r in career_path_roles if r[0] and r[0].strip()]
        
        all_roles = list(set(job_roles + career_roles))
        if not all_roles:
            all_roles = [f"{domain} Specialist"]
        
        # Get skills
        skills_query = db.query(Skills).filter(Skills.domain == domain).all()
        required_skills = [skill.skill_name for skill in skills_query if skill.skill_name][:10]
        
        # Get tools from career paths
        career_paths = db.query(CareerPaths).filter(CareerPaths.domain == domain).all()
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
        
        if domain in domain_tools_map:
            all_tools.update(domain_tools_map[domain])
        
        required_tools = list(all_tools)[:10]
        
        # Get market trends (simplified)
        market_trends = {
            "demand_level": "High",
            "growth_potential": "Excellent"
        }
        
        return {
            "job_roles": all_roles[:5],
            "required_skills": required_skills,
            "required_tools": required_tools,
            "market_trends": market_trends
        }
    except Exception as e:
        print(f"Error getting career path suggestions: {e}")
        return {
            "job_roles": [f"{domain} Specialist"],
            "required_skills": [],
            "required_tools": [],
            "market_trends": {}
        }

@router.post("/{user_id}/submit")
def submit_user_feedback(
    user_id: str,
    feedback_request: UserFeedbackRequest,
    db: Session = Depends(get_db)
):
    """Submit user feedback and store it in the database."""
    # Verify user exists
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Create feedback entry
    feedback_id = _generate_feedback_id(db)
    new_feedback = FeedbackModel(
        feedback_id=feedback_id,
        user_id=user_id,
        source="self",  # User's own feedback
        content=feedback_request.content
    )
    
    db.add(new_feedback)
    db.commit()
    db.refresh(new_feedback)
    
    return {
        "message": "Feedback submitted successfully",
        "feedback_id": new_feedback.feedback_id,
        "created_at": new_feedback.created_at.isoformat() if new_feedback.created_at else None
    }

