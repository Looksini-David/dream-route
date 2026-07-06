from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from sqlalchemy.orm import Session
from database import get_db
from models import UserQuizAttempts, AITasks, Quizzes, User, TaskStatusEnum, TaskFrequencyEnum, Skills, CareerPaths
from datetime import datetime, timedelta
import json
import random
import string

router = APIRouter(
    prefix="/ai-tasks",
    tags=["AI Tasks"]
)

def _generate_task_id(db: Session) -> str:
    """Generate a unique task_id in format T####."""
    max_attempts = 100
    for _ in range(max_attempts):
        # Generate T followed by 4 digits (e.g., T0001, T0027, T9999)
        task_num = random.randint(1, 9999)
        task_id = f"T{task_num:04d}"
        
        # Check if ID already exists
        existing = db.query(AITasks).filter(AITasks.task_id == task_id).first()
        if not existing:
            return task_id
    
    # Fallback: use timestamp-based ID if all attempts fail
    timestamp = int(datetime.now().timestamp())
    return f"T{timestamp % 100000:05d}"

@router.get("/{user_id}")
def get_ai_tasks(user_id: str, db: Session = Depends(get_db)):
    """
    Get AI-generated tasks based on user's best domain, job roles, user type, and skill level.
    Returns tasks with instructions, duration, and progress tracking.
    """
    # Get user information
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_type = user.role.value  # "student" or "fresher"
    
    # Get latest quiz attempt
    attempt = (
        db.query(UserQuizAttempts)
        .filter(UserQuizAttempts.user_id == user_id)
        .order_by(UserQuizAttempts.taken_on.desc())
        .first()
    )

    if not attempt:
        raise HTTPException(status_code=404, detail="No quiz attempt found for user. Please complete the quiz first.")
    
    if not attempt.best_domain:
        raise HTTPException(status_code=404, detail="No best domain found in quiz result. Please complete the quiz first.")

    best_domain = attempt.best_domain
    
    # Determine skill level from readiness_level or calculate from score
    skill_level = attempt.readiness_level or "beginner"
    if not skill_level or skill_level not in ["beginner", "medium", "high"]:
        # Calculate from score if readiness_level is not set
        score = attempt.score or 0
        if score >= 70:
            skill_level = "high"
        elif score >= 40:
            skill_level = "medium"
        else:
            skill_level = "beginner"

    # Get job roles from CareerPaths FIRST (more reliable for domain matching)
    career_path_roles = db.query(CareerPaths.role_name).filter(
        CareerPaths.domain == best_domain
    ).distinct().all()
    career_roles = [r[0] for r in career_path_roles if r[0] and r[0].strip()]
    
    # Also get job roles (titles) from Quizzes for this domain - ensure exact match
    titles_query = db.query(Quizzes.title).filter(
        Quizzes.domain == best_domain
    ).distinct().all()
    quiz_roles = [t[0] for t in titles_query if t[0] and t[0].strip()]
    
    # Prioritize CareerPaths roles, then add Quiz roles that don't conflict
    # This ensures we get roles that are definitely in the correct domain
    all_roles = list(career_roles)  # Start with CareerPaths roles
    for role in quiz_roles:
        if role not in all_roles:
            all_roles.append(role)
    
    # If no job roles found, create default task
    if not all_roles:
        all_roles = [f"{best_domain} Specialist"]
    
    job_roles = all_roles
    
    # Debug: Log to verify domain matching
    print(f"Domain: {best_domain}, Found {len(job_roles)} roles: {job_roles}")

    # Get career path data (skills, tools, roadmap) for intelligent task generation
    skills_query = db.query(Skills).filter(Skills.domain == best_domain).all()
    required_skills = [skill.skill_name for skill in skills_query if skill.skill_name]
    
    # Get tools from career paths
    career_paths = db.query(CareerPaths).filter(CareerPaths.domain == best_domain).all()
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
    
    required_tools = list(all_tools)[:10]  # Top 10 tools
    
    # Get roadmap suggestions for project ideas
    roadmap_projects = []
    for cp in career_paths:
        if cp.roadmap_suggestion:
            roadmap_projects.extend([
                line.strip() for line in cp.roadmap_suggestion.split('\n') 
                if 'project' in line.lower() or 'build' in line.lower() or 'create' in line.lower()
            ])

    # Get existing tasks for this user
    existing_tasks = db.query(AITasks).filter(AITasks.user_id == user_id).all()
    
    # Check if existing tasks match the current domain
    # If not, delete them to avoid showing wrong domain tasks
    tasks_to_delete = []
    for task in existing_tasks:
        task_matches_domain = (
            best_domain.lower() in task.task_name.lower() or
            best_domain.lower() in (task.guidelines or "").lower() or
            any(role.lower() in task.task_name.lower() for role in job_roles)
        )
        if not task_matches_domain:
            tasks_to_delete.append(task)
    
    # Delete tasks that don't match the current domain
    for task in tasks_to_delete:
        db.delete(task)
        existing_tasks.remove(task)
    
    if tasks_to_delete:
        db.commit()
        print(f"Deleted {len(tasks_to_delete)} tasks that didn't match domain {best_domain}")
    
    # Generate tasks based on job roles (one task per role)
    tasks_data = []
    
    if not existing_tasks and job_roles:
        # Create new tasks for each job role
        for idx, role in enumerate(job_roles[:2]):  # Limit to 2 main tasks
            # Adjust duration based on skill level
            if skill_level == "beginner":
                task_duration_hours = 3 if idx == 0 else 4  # More time for beginners
            elif skill_level == "medium":
                task_duration_hours = 2 if idx == 0 else 3
            else:  # high
                task_duration_hours = 1 if idx == 0 else 2  # Less time for advanced
            
            # Generate task based on role, domain, skills, tools, user type, and skill level
            task_guidelines = _generate_task_guidelines(
                best_domain, 
                role, 
                required_skills[:5] if required_skills else [],  # Top 5 skills
                required_tools[:5] if required_tools else [],  # Top 5 tools
                roadmap_projects[:2] if roadmap_projects else [],  # Top 2 project ideas
                user_type,  # student or fresher
                skill_level  # beginner, medium, or high
            )
            
            # Generate unique task_id
            task_id = _generate_task_id(db)
            
            new_task = AITasks(
                task_id=task_id,
                user_id=user_id,
                task_name=f"{role} - Task {idx + 1}",
                guidelines=task_guidelines,
                frequency=TaskFrequencyEnum.daily,
                status=TaskStatusEnum.pending,
                due_date=datetime.now() + timedelta(hours=task_duration_hours)
            )
            db.add(new_task)
            db.flush()
            tasks_data.append({
                "task_id": new_task.task_id,
                "task_name": new_task.task_name,
                "guidelines": new_task.guidelines,
                "duration_hours": task_duration_hours,
                "status": new_task.status.value,
                "due_date": new_task.due_date.isoformat() if new_task.due_date else None
            })
        
        db.commit()
    else:
        # Return existing tasks - but verify they match the current domain
        # Filter tasks to only include those that match the current best_domain
        # (This handles cases where user's domain changed after retaking quiz)
        domain_matching_tasks = []
        for task in existing_tasks:
            # Check if task name or guidelines mention the current domain
            task_matches = (
                best_domain.lower() in task.task_name.lower() or
                best_domain.lower() in (task.guidelines or "").lower()
            )
            if task_matches or len(existing_tasks) == 1:
                # Include task if it matches domain or if it's the only task
                domain_matching_tasks.append(task)
        
        # If no matching tasks found, we'll create new ones below
        if not domain_matching_tasks:
            existing_tasks = []  # Force creation of new tasks
        else:
            existing_tasks = domain_matching_tasks
        
        for task in existing_tasks:
            duration_hours = 2
            if task.due_date and task.created_at:
                try:
                    # Handle both datetime.datetime and datetime.date types
                    from datetime import date as date_type
                    
                    due_date = task.due_date
                    created_at = task.created_at
                    
                    # Convert to datetime if needed
                    if isinstance(due_date, date_type) and not isinstance(due_date, datetime):
                        due_date = datetime.combine(due_date, datetime.min.time())
                    if isinstance(created_at, date_type) and not isinstance(created_at, datetime):
                        created_at = datetime.combine(created_at, datetime.min.time())
                    
                    if isinstance(due_date, datetime) and isinstance(created_at, datetime):
                        duration = due_date - created_at
                        duration_hours = max(1, int(duration.total_seconds() / 3600))
                except Exception as e:
                    # If calculation fails, use default duration
                    print(f"Error calculating duration: {e}")
                    duration_hours = 2
            
            tasks_data.append({
                "task_id": task.task_id,
                "task_name": task.task_name,
                "guidelines": task.guidelines,
                "duration_hours": duration_hours,
                "status": task.status.value,
                "due_date": task.due_date.isoformat() if task.due_date else None,
                "created_at": task.created_at.isoformat() if task.created_at else None
            })

    # If no tasks were created or found, create a default task
    if not tasks_data:
        # Create a default task based on domain with career path data
        default_role = job_roles[0] if job_roles else f"{best_domain} Specialist"
        
        # Adjust duration based on skill level
        if skill_level == "beginner":
            default_duration = 3
        elif skill_level == "medium":
            default_duration = 2
        else:  # high
            default_duration = 1
            
        task_guidelines = _generate_task_guidelines(
            best_domain,
            default_role,
            required_skills[:5] if required_skills else [],
            required_tools[:5] if required_tools else [],
            roadmap_projects[:1] if roadmap_projects else [],
            user_type,  # student or fresher
            skill_level  # beginner, medium, or high
        )
        
        # Generate unique task_id
        task_id = _generate_task_id(db)
        
        new_task = AITasks(
            task_id=task_id,
            user_id=user_id,
            task_name=f"{best_domain} - Task 1",
            guidelines=task_guidelines,
            frequency=TaskFrequencyEnum.daily,
            status=TaskStatusEnum.pending,
            due_date=datetime.now() + timedelta(hours=default_duration)
        )
        db.add(new_task)
        db.flush()
        db.commit()
        
        tasks_data.append({
            "task_id": new_task.task_id,
            "task_name": new_task.task_name,
            "guidelines": new_task.guidelines,
            "duration_hours": default_duration,
            "status": new_task.status.value,
            "due_date": new_task.due_date.isoformat() if new_task.due_date else None
        })

    return {
        "best_domain": best_domain,
        "job_roles": job_roles if job_roles else [f"{best_domain} Specialist"],
        "required_skills": required_skills[:10] if required_skills else [],
        "required_tools": required_tools[:10] if required_tools else [],
        "user_type": user_type,
        "skill_level": skill_level,
        "tasks": tasks_data
    }

def _generate_task_guidelines(
    domain: str, 
    role: str, 
    skills: list = None, 
    tools: list = None, 
    project_ideas: list = None,
    user_type: str = "student",
    skill_level: str = "beginner"
) -> str:
    """Generate AI task guidelines based on domain, role, skills, tools, project ideas, user type, and skill level."""
    skills = skills or []
    tools = tools or []
    project_ideas = project_ideas or []
    
    # Adjust complexity based on skill level
    complexity_note = ""
    if skill_level == "beginner":
        complexity_note = "\n\nNote: This is a beginner-level task. Focus on understanding the basics and following tutorials."
    elif skill_level == "medium":
        complexity_note = "\n\nNote: This is an intermediate-level task. Apply your knowledge and experiment with variations."
    else:  # high
        complexity_note = "\n\nNote: This is an advanced-level task. Challenge yourself with innovative solutions and best practices."
    
    # Adjust expectations based on user type
    user_type_note = ""
    if user_type == "fresher":
        user_type_note = "\n\nAs a fresher, focus on building a portfolio-ready project that demonstrates your skills to potential employers."
    else:  # student
        user_type_note = "\n\nAs a student, use this task to practice and learn. Don't worry about perfection - focus on understanding concepts."
    
    # Build skills section
    skills_text = ""
    if skills:
        skills_text = f"\n\nRequired Skills to Practice:\n" + "\n".join([f"- {skill}" for skill in skills[:5]])
    
    # Build tools section
    tools_text = ""
    if tools:
        tools_text = f"\n\nRecommended Tools:\n" + "\n".join([f"- {tool}" for tool in tools[:5]])
    
    # Use project idea if available, otherwise generate based on role
    project_description = ""
    if project_ideas:
        project_description = project_ideas[0]
    else:
        # Generate project description based on domain and role
        project_description = f"Create a practical {role} project in {domain}"
    
    # Base guidelines template with user type and skill level considerations
    guidelines = f"""Task: {project_description}
Based on your recommended career path in {domain} as a {role}
Skill Level: {skill_level.capitalize()} | User Type: {user_type.capitalize()}{complexity_note}{user_type_note}

Instructions:
1. Research best practices and industry standards for {role} in {domain}
2. Plan your project structure and approach
3. Implement the project using relevant technologies
4. Apply {domain} principles and methodologies
5. Document your process, decisions, and learnings
6. Test and refine your work{skills_text}{tools_text}

Deliverables:
- Complete project files/code
- Documentation explaining your approach
- Screenshots or demo (if applicable)

Submit: Project files, documentation, and any supporting materials"""

    # Domain-specific enhancements
    guidelines_map = {
        "Design": {
            "UI/UX Designer": f"""Task: Create a mobile app UI design
Based on your recommended career path in {domain} as a {role}
Skill Level: {skill_level.capitalize()} | User Type: {user_type.capitalize()}{complexity_note}{user_type_note}

Instructions:
1. Design a landing page for a mobile application
2. Use {', '.join(tools[:3]) if tools else 'Figma or Adobe XD'}
3. Include: Logo, Navigation, Hero section, Features section, Footer
4. Apply design principles: Color theory, Typography, Spacing{skills_text}
5. Export design as images (PNG/JPG)

Submit: 3-5 screenshots of your design""",
            "Graphic Designer": f"""Task: Create a brand identity package
Based on your recommended career path in {domain} as a {role}
Skill Level: {skill_level.capitalize()} | User Type: {user_type.capitalize()}{complexity_note}{user_type_note}

Instructions:
1. Design a logo for a fictional company
2. Create color palette (3-5 colors)
3. Design business card
4. Create social media banner (1200x600px)
5. Use {', '.join(tools[:2]) if tools else 'Adobe Illustrator or Photoshop'}{skills_text}

Submit: Logo file, Color palette image, Business card design, Social media banner"""
        },
        "Web Development": {
            "Frontend Developer": f"""Task: Build a responsive portfolio website
Based on your recommended career path in {domain} as a {role}
Skill Level: {skill_level.capitalize()} | User Type: {user_type.capitalize()}{complexity_note}{user_type_note}

Instructions:
1. Create HTML structure
2. Style with CSS (use Flexbox/Grid)
3. Make it responsive for mobile, tablet, desktop
4. Include: About, Projects, Contact sections
5. Add smooth scrolling and animations{skills_text}
6. Use {', '.join(tools[:3]) if tools else 'VS Code, Git'}

Submit: GitHub repository link or live demo URL""",
            "Full Stack Developer": f"""Task: Create a todo application
Based on your recommended career path in {domain} as a {role}
Skill Level: {skill_level.capitalize()} | User Type: {user_type.capitalize()}{complexity_note}{user_type_note}

Instructions:
1. Build frontend (React/HTML/CSS)
2. Create backend API (Node.js/Python)
3. Connect to database
4. Features: Add, Edit, Delete, Mark complete
5. Deploy to hosting service{skills_text}
6. Use {', '.join(tools[:4]) if tools else 'VS Code, Git, Node.js'}

Submit: GitHub repository link and live demo URL"""
        },
    }

    # Check if we have a specific guideline for this domain/role combination
    domain_guidelines = guidelines_map.get(domain, {})
    if role in domain_guidelines:
        return domain_guidelines[role]
    
    return guidelines

@router.post("/{task_id}/upload")
async def upload_task_file(
    task_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Upload task submission file."""
    # Get task
    task = db.query(AITasks).filter(AITasks.task_id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # In a real implementation, save file to storage (S3, local storage, etc.)
    # For now, read file content to verify it's uploaded
    try:
        file_content = await file.read()
        file_size = len(file_content)
        
        # Update task status to completed
        task.status = TaskStatusEnum.completed
        db.commit()
        db.refresh(task)
        
        return {
            "message": "Task file uploaded successfully",
            "task_id": task_id,
            "filename": file.filename,
            "file_size": file_size,
            "status": task.status.value
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error uploading file: {str(e)}")

@router.post("/{task_id}/ai-feedback")
def get_ai_feedback(task_id: str, db: Session = Depends(get_db)):
    """Get AI-generated feedback for submitted task."""
    task = db.query(AITasks).filter(AITasks.task_id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Generate AI feedback (in real implementation, use AI service)
    feedback = f"""Great work on completing the {task.task_name}!

Strengths:
- Good understanding of basic concepts
- Clear structure in your work
- Following best practices

Areas to Improve:
- Add more details to enhance quality
- Consider advanced techniques
- Practice more to build expertise

AI Usage Note: Remember to use AI tools as assistants, not replacements. 
Use AI for research, idea generation, and learning, but always understand 
the concepts yourself."""

    return {
        "task_id": task_id,
        "feedback": feedback,
        "suggestions": [
            "Practice more similar tasks",
            "Study advanced techniques",
            "Build a portfolio"
        ]
    }

