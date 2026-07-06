# services/resume_feedback.py
"""
AI-powered feedback generation for resume analysis.
Generates personalized feedback and tips based on resume analysis results.
"""

def generate_ai_feedback(analysis_result: dict, domain: str) -> dict:
    """
    Generate AI-powered feedback and tips based on resume analysis.
    
    Args:
        analysis_result: Dictionary containing analysis results from analyze_ats
        domain: User's career domain
    
    Returns:
        Dictionary with 'feedback' and 'tips' keys
    """
    ats_score = analysis_result.get("ats_score", 0)
    formatting_score = analysis_result.get("formatting_score", 0)
    clarity_score = analysis_result.get("clarity_score", 0)
    section_score = analysis_result.get("section_score", 0)
    sections_found = analysis_result.get("sections_found", [])
    skill_score = analysis_result.get("skill_score", 0)
    matched_skills = analysis_result.get("matched_skills", [])
    missing_skills = analysis_result.get("missing_skills", [])
    
    # Generate overall feedback
    feedback_parts = []
    
    # Overall Score Feedback
    if ats_score >= 80:
        feedback_parts.append(f"🎉 Excellent! Your resume has an ATS score of {ats_score}%, which is outstanding. Your resume is well-optimized and should pass most ATS systems.")
    elif ats_score >= 60:
        feedback_parts.append(f"✅ Good job! Your resume has an ATS score of {ats_score}%. You're on the right track, but there's room for improvement to maximize your chances.")
    elif ats_score >= 40:
        feedback_parts.append(f"⚠️ Your resume has an ATS score of {ats_score}%. While it has some strengths, significant improvements are needed to be competitive in the {domain} field.")
    else:
        feedback_parts.append(f"🔴 Your resume has an ATS score of {ats_score}%. Your resume needs substantial improvements to be ATS-compatible and competitive in {domain}.")
    
    # Skill Matching Feedback
    if skill_score >= 70:
        feedback_parts.append(f"✨ Great skill alignment! You've matched {len(matched_skills)} out of {len(matched_skills) + len(missing_skills)} key skills for {domain}.")
    elif skill_score >= 40:
        feedback_parts.append(f"📊 Moderate skill coverage: You've matched {len(matched_skills)} skills, but {len(missing_skills)} important {domain} skills are missing.")
    else:
        feedback_parts.append(f"⚠️ Low skill coverage: You're missing {len(missing_skills)} critical skills for {domain}. Focus on adding these to improve your resume.")
    
    # Section Analysis Feedback
    expected_sections = ["summary", "experience", "skills", "projects", "education", "certifications"]
    missing_sections = [s for s in expected_sections if s not in sections_found]
    
    if len(sections_found) >= 5:
        feedback_parts.append(f"📋 Well-structured resume! You have {len(sections_found)} key sections, which is excellent for ATS parsing.")
    elif len(sections_found) >= 3:
        feedback_parts.append(f"📄 Your resume has {len(sections_found)} sections. Consider adding {', '.join(missing_sections[:2])} to improve structure.")
    else:
        feedback_parts.append(f"📝 Your resume is missing several important sections. Add {', '.join(missing_sections[:3])} to make it more complete.")
    
    # Formatting Feedback
    if formatting_score >= 8:
        feedback_parts.append("🎨 Excellent formatting! Your resume is well-formatted and easy to read.")
    elif formatting_score >= 5:
        feedback_parts.append("📐 Your formatting is decent, but could be improved. Use bullet points and keep paragraphs concise.")
    else:
        feedback_parts.append("🔧 Formatting needs improvement. Use clear bullet points, avoid long paragraphs, and ensure consistent spacing.")
    
    # Clarity Feedback
    if clarity_score >= 8:
        feedback_parts.append("💬 Clear and professional language! Your resume communicates effectively.")
    elif clarity_score >= 5:
        feedback_parts.append("✍️ Your writing is mostly clear, but review for grammar and clarity to make it more professional.")
    else:
        feedback_parts.append("📝 Improve clarity and grammar. Proofread carefully and use action verbs to describe your achievements.")
    
    # Generate actionable tips
    tips = []
    
    # Tips based on missing skills
    if missing_skills:
        top_missing = missing_skills[:3]
        tips.append(f"Add these critical {domain} skills: {', '.join(top_missing)}. These are highly valued in your field.")
    
    # Tips based on missing sections
    if missing_sections:
        tips.append(f"Include a '{missing_sections[0].capitalize()}' section to showcase your {missing_sections[0]} and improve ATS compatibility.")
    
    # Tips based on formatting
    if formatting_score < 7:
        tips.append("Use bullet points (•) instead of long paragraphs. ATS systems prefer concise, scannable content.")
        tips.append("Keep your resume length to 1-2 pages. Focus on the most relevant and recent experiences.")
    
    # Tips based on skill score
    if skill_score < 50:
        tips.append("Quantify your achievements with numbers (e.g., 'Increased sales by 30%' or 'Managed team of 5').")
        tips.append("Use industry-specific keywords from job descriptions in your field to improve ATS matching.")
    
    # General tips
    if ats_score < 60:
        tips.append("Tailor your resume for each job application. Highlight skills and experiences most relevant to the position.")
        tips.append("Use a clean, professional format. Avoid graphics, tables, or complex layouts that ATS systems can't parse.")
    
    # Domain-specific tips
    domain_tips = {
        "Design": [
            "Include a portfolio link or mention specific design projects with tools used (Figma, Adobe XD, etc.).",
            "Highlight your design process and methodology, not just final designs."
        ],
        "Web Development": [
            "List specific technologies and frameworks (React, Node.js, etc.) with proficiency levels.",
            "Include links to GitHub repositories or live projects to showcase your work."
        ],
        "AI & Data Science": [
            "Mention specific algorithms, models, or datasets you've worked with.",
            "Include metrics and results from your data science projects (accuracy, performance improvements, etc.)."
        ],
        "Mobile Development": [
            "Specify platforms (iOS, Android, or cross-platform) and development tools used.",
            "Include app store links or mention download numbers if available."
        ]
    }
    
    if domain in domain_tips:
        tips.extend(domain_tips[domain][:2])
    
    # Ensure we have at least 3 tips
    while len(tips) < 3:
        tips.append("Review your resume for typos and grammatical errors. A polished resume shows attention to detail.")
        if len(tips) >= 5:
            break
    
    return {
        "feedback": " ".join(feedback_parts),
        "tips": tips[:5]  # Return top 5 tips
    }

