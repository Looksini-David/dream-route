from sqlalchemy import Column, DateTime, Float, String, Integer, Text, ForeignKey, TIMESTAMP, func, func, text, Enum
from database import Base
import enum
from pydantic import BaseModel
from sqlalchemy import LargeBinary

# ---------------------------
# ENUM DEFINITIONS
# ---------------------------

class RoleEnum(str, enum.Enum):
    student = "student"
    fresher = "fresher"

class OptionEnum(str, enum.Enum):
    A = "A"
    B = "B"
    C = "C"
    D = "D"

class QuestionTypeEnum(str, enum.Enum):
    creativity = "creativity"
    logical_thinking = "logical_thinking"
    communication = "communication"
    technical = "technical"
    situational = "situational"
    softskill = "softskill"

class StatusEnum(str, enum.Enum):
    active = "active"
    inactive = "inactive"

class LevelEnum(str, enum.Enum):
    beginner = "beginner"
    medium = "medium"
    high = "high"

class AnalysisStatusEnum(str, enum.Enum):
    pending = "pending"
    completed = "completed"

class FeedbackSourceEnum(str, enum.Enum):
    AI = "AI"
    self = "self"

class TaskFrequencyEnum(str, enum.Enum):
    daily = "daily"
    weekly = "weekly"

class TaskStatusEnum(str, enum.Enum):
    pending = "pending"
    completed = "completed"

class AdminRoleEnum(str, enum.Enum):
    superadmin = "superadmin"
    subadmin = "subadmin"
    
# ---------------------------
# Pydantic Models
# ---------------------------

class QuizAnswer(BaseModel):
    question_id: str
    selected_option: str

class QuizSubmission(BaseModel):
    user_email: str
    answers: list[QuizAnswer]

# ---------------------------
# DATABASE TABLES
# ---------------------------

class User(Base):
    __tablename__ = "users"

    user_id = Column(
        String(5),
        primary_key=True,
        server_default=text("('U' || LPAD(nextval('user_seq')::text, 4, '0'))")
    )
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    profile_image = Column(LargeBinary)  # No type hint!
    role = Column(Enum(RoleEnum), nullable=False)
    qualification = Column(String(255), nullable=True)
    location = Column(String(255), nullable=True)
    join_date = Column(TIMESTAMP, server_default=func.now(), nullable=True)
    resume_url = Column(String(255), nullable=True)
    resume_score = Column(Integer, nullable=True)
    resume_blob = Column(LargeBinary, nullable=True)
    status = Column(Enum(StatusEnum), nullable=True)
    skills = Column(Text, nullable=True)  # comma-separated

class Quizzes(Base):
    __tablename__ = "quizzes"

    quiz_id = Column(String(5), primary_key=True)
    domain = Column(String(255))
    title = Column(String(255))
    created_at = Column(TIMESTAMP)

class Questions(Base):
    __tablename__ = "questions"

    question_id = Column(String, primary_key=True)
    quiz_id = Column(String, ForeignKey("quizzes.quiz_id"))
    question_text = Column(Text, nullable=False)
    option_a = Column(Text, nullable=False)
    option_b = Column(Text, nullable=False)
    option_c = Column(Text, nullable=False)
    option_d = Column(Text, nullable=False)
    correct_option = Column(Enum(OptionEnum))
    type = Column(Enum(QuestionTypeEnum))
    created_at = Column(TIMESTAMP)

class UserQuizAttempts(Base):
    __tablename__ = "userquizattempts"

    attempt_id = Column(
        String(10),
        primary_key=True,
        server_default=text("('A' || LPAD(nextval('user_quiz_attempt_seq')::text, 4, '0'))")
    )
    user_id = Column(String(5), ForeignKey("users.user_id"))
    quiz_id = Column(String(5), ForeignKey("quizzes.quiz_id"))
    score = Column(Integer)
    readiness_level = Column(String(10))
    taken_on = Column(TIMESTAMP, server_default=func.now())

    # ✅ new columns
    best_domain = Column(String(50))

    # ✅ domain-wise scores
    ai_data_science = Column(Float, default=0)
    data_analytics = Column(Float, default=0)
    it_management = Column(Float, default=0)
    database = Column(Float, default=0)
    cloud_devops = Column(Float, default=0)
    software_development = Column(Float, default=0)
    networking = Column(Float, default=0)
    mobile_development = Column(Float, default=0)
    design = Column(Float, default=0)
    cybersecurity = Column(Float, default=0)
    web_development = Column(Float, default=0)

class Skills(Base):
    __tablename__ = "skills"

    skill_id = Column(String(5), primary_key=True)
    domain = Column(String(255), nullable=False)
    skill_name = Column(String(255), nullable=False)
    description = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())

class UserSkills(Base):
    __tablename__ = "userskills"

    user_skill_id = Column(String(6), primary_key=True)
    user_id = Column(String(5), ForeignKey("users.user_id"), nullable=False)
    skill_id = Column(String(5), ForeignKey("skills.skill_id"), nullable=False)
    level = Column(Enum(LevelEnum))
    missing = Column(String(5), default="false")
    created_at = Column(TIMESTAMP, server_default=func.now())

class ResumeRules(Base):
    __tablename__ = "resumerules"

    rule_id = Column(
        String(10),
        primary_key=True,
        server_default=text("('R' || LPAD(nextval('resume_rules_seq')::text, 4, '0'))")
    )
    user_id = Column(String(5), ForeignKey("users.user_id"), nullable=False)
    resume_url = Column(String(255))
    analysis_status = Column(Enum(AnalysisStatusEnum), default=AnalysisStatusEnum.pending)
    score = Column(Integer, nullable=True)
    matched_skills = Column(Text, nullable=True)
    missing_skills = Column(Text, nullable=True)
    domain = Column(String(255), nullable=True)
    resume_blob = Column(LargeBinary, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

class Feedback(Base):
    __tablename__ = "feedback"

    feedback_id = Column(String(10), primary_key=True)
    user_id = Column(String(5), ForeignKey("users.user_id"), nullable=False)
    source = Column(Enum(FeedbackSourceEnum), nullable=False)
    content = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())

class CareerPaths(Base):
    __tablename__ = "careerpaths"

    career_id = Column(String, primary_key=True)
    role_name = Column(String(255))
    domain = Column(String(255))
    description = Column(Text)
    required_skills = Column(Text)
    tools = Column(Text)
    roadmap_suggestion = Column(Text)
    job_market_info = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())

class UserCareerProgress(Base):
    __tablename__ = "usercareerprogress"

    progress_id = Column(String(10), primary_key=True)
    user_id = Column(String(5), ForeignKey("users.user_id"), nullable=False)
    career_id = Column(String, ForeignKey("careerpaths.career_id"), nullable=False)
    progress_percentage = Column(Integer, default=0)
    last_updated = Column(TIMESTAMP, server_default=func.now())
    notifications = Column(Text)

class RoadmapTimeline(Base):
    __tablename__ = "roadmaptimeline"

    timeline_id = Column(String(10), primary_key=True)
    user_id = Column(String(5), ForeignKey("users.user_id"), nullable=False)
    step_name = Column(String(255))
    status = Column(String(50), default="pending")
    due_date = Column(DateTime)
    created_at = Column(TIMESTAMP, server_default=func.now())

class AITasks(Base):
    __tablename__ = "aitasks"

    task_id = Column(String(10), primary_key=True)
    user_id = Column(String(5), ForeignKey("users.user_id"), nullable=False)
    task_name = Column(String(255))
    guidelines = Column(Text)
    frequency = Column(Enum(TaskFrequencyEnum))
    status = Column(Enum(TaskStatusEnum), default=TaskStatusEnum.pending)
    created_at = Column(TIMESTAMP, server_default=func.now())
    due_date = Column(DateTime)

class AdminUsers(Base):
    __tablename__ = "adminusers"

    admin_id = Column(String(10), primary_key=True)
    name = Column(String(255))
    email = Column(String(255), unique=True)
    password = Column(String(255))
    role = Column(Enum(AdminRoleEnum))
    created_at = Column(TIMESTAMP, server_default=func.now())

class IndustryData(Base):
    __tablename__ = "industrydata"

    industry_id = Column(String(10), primary_key=True)
    skill_name = Column(String(255))
    type = Column(String(255))
    demand = Column(Integer)
    salary = Column(String(50))
    created_at = Column(TIMESTAMP, server_default=func.now())

class QuizScoreAnalysis(Base):
    __tablename__ = "quizscoreanalysis"

    analysis_id = Column(String(10), primary_key=True)
    user_id = Column(String(5), ForeignKey("users.user_id"), nullable=False)
    quiz_id = Column(String(10), ForeignKey("quizzes.quiz_id"), nullable=False)
    score = Column(Integer)
    type = Column(Enum(QuestionTypeEnum))
    created_at = Column(TIMESTAMP, server_default=func.now())
