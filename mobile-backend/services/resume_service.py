# services/resume_service.py

import re
import fitz  # PyMuPDF → pdf text extraction
from sentence_transformers import SentenceTransformer, util

# Load AI Model (only once)
model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

# -------------------------------------------
# Extract text from PDF
# -------------------------------------------
def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    try:
        pdf = fitz.open(stream=pdf_bytes, filetype="pdf")
        text = ""
        for page in pdf:
            text += page.get_text()
        return text.lower()
    except Exception as e:
        print("PDF Extraction Error:", e)
        return ""

# -------------------------------------------
# Skill Extraction using Regex + AI Semantic
# -------------------------------------------
def extract_skills(text: str, domain_skills: list[str]) -> list[str]:
    found = []
    for skill in domain_skills:
        skill_clean = skill.lower()
        if skill_clean in text:
            found.append(skill)
        else:
            # AI semantic match (if text contains similar meaning)
            score = util.cos_sim(
                model.encode(skill_clean),
                model.encode(text)
            )
            if score.item() > 0.40:   # threshold for semantic match
                found.append(skill)
    return list(set(found))

# -------------------------------------------
# AI Resume Scoring
# -------------------------------------------
def calculate_score(matched: list[str], domain_skills: list[str]) -> int:
    if not domain_skills:
        return 0
    ratio = len(matched) / len(domain_skills)
    score = int(ratio * 100)
    return max(0, min(score, 100))

# -------------------------------------------
# Main Resume Analysis
# -------------------------------------------
def analyze_resume(pdf_bytes: bytes, domain_skills: list[str]) -> dict:
    text = extract_text_from_pdf(pdf_bytes)
    if not text:
        return {"score": 0, "matched_skills": [], "missing_skills": []}

    matched_skills = extract_skills(text, domain_skills)
    missing_skills = [s for s in domain_skills if s not in matched_skills]
    score = calculate_score(matched_skills, domain_skills)

    return {
        "score": score,
        "matched_skills": matched_skills,
        "missing_skills": missing_skills
    }
