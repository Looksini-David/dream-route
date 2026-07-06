# services/resume_ats.py

import re
import fitz
from sentence_transformers import SentenceTransformer, util
from services.resume_service import extract_skills

# Load AI Model
model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

# -------------------------------
# PDF TEXT EXTRACTION
# -------------------------------
def extract_text(pdf: bytes) -> str:
    try:
        doc = fitz.open(stream=pdf, filetype="pdf")
        text = ""
        for p in doc:
            text += p.get_text()
        return text.lower()
    except:
        return ""

# -------------------------------
# SECTION DETECTION
# -------------------------------
def score_sections(text: str):
    sections = {
        "summary": r"(summary|objective)",
        "experience": r"(experience|work history)",
        "skills": r"(skills|technical skills)",
        "projects": r"(projects|personal projects)",
        "education": r"(education|academic)",
        "certifications": r"(certification|courses)",
    }

    found = []
    for k, pattern in sections.items():
        if re.search(pattern, text):
            found.append(k)

    score = int((len(found) / len(sections)) * 10)  # max 10 points
    return score, found

# -------------------------------
# FORMATTING SCORE
# -------------------------------
def score_formatting(text: str):
    bullets = len(re.findall(r"•|- ", text))
    long_paragraphs = len([p for p in text.split("\n") if len(p) > 300])

    score = 10
    if bullets < 5:
        score -= 3
    if long_paragraphs > 5:
        score -= 3
    if len(text) < 500:
        score -= 2
    return max(0, score)

# -------------------------------
# GRAMMAR / CLARITY SCORE
# -------------------------------
def clarity_score(text: str):
    grammar_issues = len(re.findall(r"\bis\b\s+is\b| {2,}", text))
    score = 10 - min(grammar_issues, 5)
    return max(0, score)

# -------------------------------
# JOB DESCRIPTION MATCH
# -------------------------------
def jd_match(text: str, jd: str):
    if not jd:
        return 0, []

    resume_embed = model.encode(text)
    jd_embed = model.encode(jd)

    similarity = util.cos_sim(resume_embed, jd_embed).item()
    score = int(similarity * 100)
    missing_keywords = [w for w in jd.split() if w.lower() not in text]
    return score, missing_keywords[:10]

# -------------------------------
# FINAL ATS SCORING
# -------------------------------
def calculate_ats_score(skill_score, fmt, clarity, sections, jd_score):
    return int(
        (skill_score * 0.40)
        + (fmt * 2)         # 10 → 20%
        + (sections * 1)    # 10 → 10%
        + (clarity * 1)     # 10 → 10%
        + (jd_score * 0.20)
    )

# -------------------------------
# MAIN ATS ANALYZER
# -------------------------------
def analyze_ats(pdf_bytes: bytes, domain_skills: list[str], jd: str = ""):
    text = extract_text(pdf_bytes)

    # Section Score
    section_score, found_sections = score_sections(text)

    # Formatting Score
    formatting = score_formatting(text)

    # Clarity Score
    clarity = clarity_score(text)

    # JD Score
    jd_score, missing_jd = jd_match(text, jd)

    # Skill Matching
    matched_skills = extract_skills(text, domain_skills)
    missing_skills = [s for s in domain_skills if s not in matched_skills]
    skill_score = int((len(matched_skills) / len(domain_skills)) * 100) if domain_skills else 0

    # Total ATS Score
    ats = calculate_ats_score(skill_score, formatting, clarity, section_score, jd_score)

    return {
        "ats_score": ats,
        "formatting_score": formatting,
        "clarity_score": clarity,
        "section_score": section_score,
        "sections_found": found_sections,
        "skill_score": skill_score,
        "matched_skills": matched_skills,
        "missing_skills": missing_skills,
        "jd_match_score": jd_score,
        "missing_jd_keywords": missing_jd[:10]
    }
