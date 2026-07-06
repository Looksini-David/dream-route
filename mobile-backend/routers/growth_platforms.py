from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import UserQuizAttempts

router = APIRouter(
    prefix="/growth-platforms",
    tags=["Growth Platforms"]
)

@router.get("/{user_id}")
def get_growth_platforms(user_id: str, db: Session = Depends(get_db)):
    """
    Get AI-suggested growth platform links based on user's best domain.
    Returns professional platforms with skill levels (beginner, intermediate, advanced).
    Includes YouTube channels (English & Tamil), free courses, online courses, and certificates.
    IT tutorials only.
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

    # Domain-specific platform links organized by skill level and category
    domain_platforms = _get_domain_platforms(best_domain)

    return {
        "best_domain": best_domain,
        "platforms": domain_platforms
    }

def _get_domain_platforms(domain: str) -> dict:
    """Get comprehensive platform links for a domain, organized by skill level and category."""
    
    # Base platforms that apply to all domains
    base_platforms = {
        "YouTube": {
            "English": [
                {
                    "title": f"{domain} Tutorials - English",
                    "url": f"https://www.youtube.com/results?search_query={domain.replace(' ', '+')}+tutorial+english",
                    "skill_level": "beginner",
                    "type": "free"
                },
                {
                    "title": f"Advanced {domain} - English",
                    "url": f"https://www.youtube.com/results?search_query=advanced+{domain.replace(' ', '+')}+tutorial",
                    "skill_level": "advanced",
                    "type": "free"
                }
            ],
            "Tamil": [
                {
                    "title": f"{domain} Tamil Tutorials",
                    "url": f"https://www.youtube.com/results?search_query={domain.replace(' ', '+')}+tamil+tutorial",
                    "skill_level": "beginner",
                    "type": "free"
                },
                {
                    "title": f"{domain} Tamil Advanced",
                    "url": f"https://www.youtube.com/results?search_query={domain.replace(' ', '+')}+tamil+advanced",
                    "skill_level": "intermediate",
                    "type": "free"
                }
            ]
        },
        "FreeCodeCamp": {
            "title": f"{domain} Free Courses",
            "url": "https://www.freecodecamp.org/learn",
            "skill_level": "beginner",
            "type": "free_certificate"
        },
        "Coursera": {
            "title": f"{domain} Specializations",
            "url": "https://www.coursera.org",
            "skill_level": "intermediate",
            "type": "online_course"
        },
        "Alison": {
            "title": f"{domain} Free Certificates",
            "url": "https://alison.com",
            "skill_level": "beginner",
            "type": "free_certificate"
        }
    }

    # Domain-specific platforms
    domain_specific = {
        "Design": {
            "YouTube": {
                "English": [
                    {
                        "title": "UI/UX Design Tutorials - English",
                        "url": "https://www.youtube.com/results?search_query=ui+ux+design+tutorial+english",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Figma Tutorials - English",
                        "url": "https://www.youtube.com/results?search_query=figma+tutorial+english",
                        "skill_level": "intermediate",
                        "type": "free"
                    },
                    {
                        "title": "Adobe XD Tutorials - English",
                        "url": "https://www.youtube.com/results?search_query=adobe+xd+tutorial+english",
                        "skill_level": "intermediate",
                        "type": "free"
                    }
                ],
                "Tamil": [
                    {
                        "title": "UI/UX Design Tamil",
                        "url": "https://www.youtube.com/results?search_query=ui+ux+design+tamil",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Figma Tamil Tutorials",
                        "url": "https://www.youtube.com/results?search_query=figma+tamil+tutorial",
                        "skill_level": "beginner",
                        "type": "free"
                    }
                ]
            },
            "FreeCodeCamp": {
                "title": "Responsive Web Design (Free Certificate)",
                "url": "https://www.freecodecamp.org/learn/2022/responsive-web-design",
                "skill_level": "beginner",
                "type": "free_certificate"
            },
            "Coursera": {
                "title": "Google UX Design Certificate",
                "url": "https://www.coursera.org/professional-certificates/google-ux-design",
                "skill_level": "beginner",
                "type": "online_course"
            },
            "Alison": {
                "title": "Graphic Design Diploma (Free)",
                "url": "https://alison.com/course/diploma-in-graphic-design",
                "skill_level": "beginner",
                "type": "free_certificate"
            },
            "Udemy": {
                "title": "UI/UX Design Courses",
                "url": "https://www.udemy.com/topic/ui-design/",
                "skill_level": "intermediate",
                "type": "online_course"
            },
            "edX": {
                "title": "Design Courses (Free Audit)",
                "url": "https://www.edx.org/learn/design",
                "skill_level": "intermediate",
                "type": "free"
            }
        },
        "Web Development": {
            "YouTube": {
                "English": [
                    {
                        "title": "Web Development Full Course - English",
                        "url": "https://www.youtube.com/results?search_query=web+development+full+course+english",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "React Tutorial - English",
                        "url": "https://www.youtube.com/results?search_query=react+tutorial+english",
                        "skill_level": "intermediate",
                        "type": "free"
                    },
                    {
                        "title": "Node.js Tutorial - English",
                        "url": "https://www.youtube.com/results?search_query=nodejs+tutorial+english",
                        "skill_level": "intermediate",
                        "type": "free"
                    }
                ],
                "Tamil": [
                    {
                        "title": "Web Development Tamil",
                        "url": "https://www.youtube.com/results?search_query=web+development+tamil",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "HTML CSS Tamil",
                        "url": "https://www.youtube.com/results?search_query=html+css+tamil+tutorial",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "JavaScript Tamil",
                        "url": "https://www.youtube.com/results?search_query=javascript+tamil+tutorial",
                        "skill_level": "intermediate",
                        "type": "free"
                    }
                ]
            },
            "FreeCodeCamp": {
                "title": "Full Stack Web Development (Free Certificate)",
                "url": "https://www.freecodecamp.org/learn/2022/responsive-web-design",
                "skill_level": "beginner",
                "type": "free_certificate"
            },
            "Coursera": {
                "title": "Web Development Specialization",
                "url": "https://www.coursera.org/specializations/web-design",
                "skill_level": "intermediate",
                "type": "online_course"
            },
            "Alison": {
                "title": "Web Development Diploma (Free)",
                "url": "https://alison.com/course/diploma-in-web-development",
                "skill_level": "beginner",
                "type": "free_certificate"
            },
            "MDN Web Docs": {
                "title": "Web Development Tutorials (Free)",
                "url": "https://developer.mozilla.org/en-US/docs/Learn",
                "skill_level": "beginner",
                "type": "free"
            },
            "W3Schools": {
                "title": "Web Development Tutorials (Free)",
                "url": "https://www.w3schools.com",
                "skill_level": "beginner",
                "type": "free"
            }
        },
        "AI & Data Science": {
            "YouTube": {
                "English": [
                    {
                        "title": "Data Science Full Course - English",
                        "url": "https://www.youtube.com/results?search_query=data+science+full+course+english",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Machine Learning Tutorial - English",
                        "url": "https://www.youtube.com/results?search_query=machine+learning+tutorial+english",
                        "skill_level": "intermediate",
                        "type": "free"
                    },
                    {
                        "title": "Python for Data Science - English",
                        "url": "https://www.youtube.com/results?search_query=python+data+science+tutorial+english",
                        "skill_level": "beginner",
                        "type": "free"
                    }
                ],
                "Tamil": [
                    {
                        "title": "Data Science Tamil",
                        "url": "https://www.youtube.com/results?search_query=data+science+tamil",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Python Tamil Tutorials",
                        "url": "https://www.youtube.com/results?search_query=python+tamil+tutorial",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Machine Learning Tamil",
                        "url": "https://www.youtube.com/results?search_query=machine+learning+tamil",
                        "skill_level": "intermediate",
                        "type": "free"
                    }
                ]
            },
            "FreeCodeCamp": {
                "title": "Data Analysis with Python (Free Certificate)",
                "url": "https://www.freecodecamp.org/learn/data-analysis-with-python",
                "skill_level": "beginner",
                "type": "free_certificate"
            },
            "Coursera": {
                "title": "IBM Data Science Certificate",
                "url": "https://www.coursera.org/professional-certificates/ibm-data-science",
                "skill_level": "beginner",
                "type": "online_course"
            },
            "Alison": {
                "title": "Data Science Diploma (Free)",
                "url": "https://alison.com/course/diploma-in-data-science",
                "skill_level": "beginner",
                "type": "free_certificate"
            },
            "Kaggle": {
                "title": "Data Science Courses (Free)",
                "url": "https://www.kaggle.com/learn",
                "skill_level": "beginner",
                "type": "free"
            }
        },
        "Mobile Development": {
            "YouTube": {
                "English": [
                    {
                        "title": "Flutter Tutorial - English",
                        "url": "https://www.youtube.com/results?search_query=flutter+tutorial+english",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "React Native Tutorial - English",
                        "url": "https://www.youtube.com/results?search_query=react+native+tutorial+english",
                        "skill_level": "intermediate",
                        "type": "free"
                    }
                ],
                "Tamil": [
                    {
                        "title": "Flutter Tamil",
                        "url": "https://www.youtube.com/results?search_query=flutter+tamil+tutorial",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Android Development Tamil",
                        "url": "https://www.youtube.com/results?search_query=android+development+tamil",
                        "skill_level": "beginner",
                        "type": "free"
                    }
                ]
            },
            "FreeCodeCamp": {
                "title": "Mobile Development (Free)",
                "url": "https://www.freecodecamp.org/learn",
                "skill_level": "beginner",
                "type": "free"
            },
            "Coursera": {
                "title": "Mobile Development Specialization",
                "url": "https://www.coursera.org/browse/computer-science/mobile-development",
                "skill_level": "intermediate",
                "type": "online_course"
            }
        },
        "Software Development": {
            "YouTube": {
                "English": [
                    {
                        "title": "Software Development Full Course - English",
                        "url": "https://www.youtube.com/results?search_query=software+development+full+course+english",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Java Tutorial - English",
                        "url": "https://www.youtube.com/results?search_query=java+tutorial+english",
                        "skill_level": "beginner",
                        "type": "free"
                    }
                ],
                "Tamil": [
                    {
                        "title": "Software Development Tamil",
                        "url": "https://www.youtube.com/results?search_query=software+development+tamil",
                        "skill_level": "beginner",
                        "type": "free"
                    },
                    {
                        "title": "Java Tamil Tutorials",
                        "url": "https://www.youtube.com/results?search_query=java+tamil+tutorial",
                        "skill_level": "beginner",
                        "type": "free"
                    }
                ]
            },
            "FreeCodeCamp": {
                "title": "Software Development (Free)",
                "url": "https://www.freecodecamp.org/learn",
                "skill_level": "beginner",
                "type": "free"
            },
            "Coursera": {
                "title": "Software Development Specialization",
                "url": "https://www.coursera.org/browse/computer-science/software-development",
                "skill_level": "intermediate",
                "type": "online_course"
            }
        }
    }

    # Return domain-specific platforms or base platforms
    return domain_specific.get(domain, base_platforms)
