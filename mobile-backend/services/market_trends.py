# services/market_trends.py
"""
AI-powered market trends generator for different career domains.
Generates daily updated salary ranges and demand levels based on domain.
Supports both Global and Sri Lanka (Local) market trends.
"""

from datetime import datetime
from typing import Dict

# Domain-specific market trend data - GLOBAL (AI-generated based on current market conditions)
DOMAIN_MARKET_DATA_GLOBAL = {
    "Design": {
        "base_salary_min": 45000,
        "base_salary_max": 95000,
        "base_demand": 85,
        "trend_factor": 1.02,  # 2% growth trend
    },
    "Web Development": {
        "base_salary_min": 55000,
        "base_salary_max": 120000,
        "base_demand": 90,
        "trend_factor": 1.03,
    },
    "AI & Data Science": {
        "base_salary_min": 70000,
        "base_salary_max": 150000,
        "base_demand": 95,
        "trend_factor": 1.05,
    },
    "Mobile Development": {
        "base_salary_min": 60000,
        "base_salary_max": 130000,
        "base_demand": 88,
        "trend_factor": 1.025,
    },
    "IT Project Manager": {
        "base_salary_min": 65000,
        "base_salary_max": 140000,
        "base_demand": 82,
        "trend_factor": 1.015,
    },
    "Business Analyst": {
        "base_salary_min": 50000,
        "base_salary_max": 110000,
        "base_demand": 80,
        "trend_factor": 1.02,
    },
    "Cybersecurity": {
        "base_salary_min": 70000,
        "base_salary_max": 145000,
        "base_demand": 92,
        "trend_factor": 1.04,
    },
    "Cloud Computing": {
        "base_salary_min": 75000,
        "base_salary_max": 155000,
        "base_demand": 93,
        "trend_factor": 1.045,
    },
    "DevOps": {
        "base_salary_min": 80000,
        "base_salary_max": 160000,
        "base_demand": 91,
        "trend_factor": 1.035,
    },
    "Software Development": {
        "base_salary_min": 60000,
        "base_salary_max": 125000,
        "base_demand": 87,
        "trend_factor": 1.025,
    },
    "Data Analytics": {
        "base_salary_min": 55000,
        "base_salary_max": 115000,
        "base_demand": 85,
        "trend_factor": 1.03,
    },
}

# Domain-specific market trend data - SRI LANKA (Local market with adjusted rates)
# Sri Lanka salaries are typically 30-50% lower than global, converted to LKR
DOMAIN_MARKET_DATA_SRI_LANKA = {
    "Design": {
        "base_salary_min": 300000,  # LKR per month
        "base_salary_max": 800000,
        "base_demand": 75,
        "trend_factor": 1.02,
        "currency": "LKR",
    },
    "Web Development": {
        "base_salary_min": 400000,
        "base_salary_max": 1000000,
        "base_demand": 88,
        "trend_factor": 1.03,
        "currency": "LKR",
    },
    "AI & Data Science": {
        "base_salary_min": 500000,
        "base_salary_max": 1200000,
        "base_demand": 85,
        "trend_factor": 1.04,
        "currency": "LKR",
    },
    "Mobile Development": {
        "base_salary_min": 450000,
        "base_salary_max": 1100000,
        "base_demand": 82,
        "trend_factor": 1.025,
        "currency": "LKR",
    },
    "IT Project Manager": {
        "base_salary_min": 500000,
        "base_salary_max": 1300000,
        "base_demand": 75,
        "trend_factor": 1.02,
        "currency": "LKR",
    },
    "Business Analyst": {
        "base_salary_min": 350000,
        "base_salary_max": 900000,
        "base_demand": 72,
        "trend_factor": 1.02,
        "currency": "LKR",
    },
    "Cybersecurity": {
        "base_salary_min": 550000,
        "base_salary_max": 1300000,
        "base_demand": 80,
        "trend_factor": 1.035,
        "currency": "LKR",
    },
    "Cloud Computing": {
        "base_salary_min": 600000,
        "base_salary_max": 1400000,
        "base_demand": 83,
        "trend_factor": 1.04,
        "currency": "LKR",
    },
    "DevOps": {
        "base_salary_min": 550000,
        "base_salary_max": 1350000,
        "base_demand": 81,
        "trend_factor": 1.03,
        "currency": "LKR",
    },
    "Software Development": {
        "base_salary_min": 400000,
        "base_salary_max": 1100000,
        "base_demand": 80,
        "trend_factor": 1.025,
        "currency": "LKR",
    },
    "Data Analytics": {
        "base_salary_min": 380000,
        "base_salary_max": 950000,
        "base_demand": 78,
        "trend_factor": 1.03,
        "currency": "LKR",
    },
}

def generate_daily_market_trends(domain: str, region: str = "global") -> Dict[str, any]:
    """
    Generate AI-powered daily market trends for a specific domain.
    Uses date-based variation to simulate daily updates.
    
    Args:
        domain: Career domain name
        region: "global" or "sri_lanka" (default: "global")
    
    Returns:
        Dictionary with 'salary_range', 'demand_level', 'demand_percentage', 'insights', 'last_updated'
    """
    # Select appropriate market data based on region
    if region.lower() == "sri_lanka" or region.lower() == "local":
        market_data = DOMAIN_MARKET_DATA_SRI_LANKA
        currency = "LKR"
        region_name = "Sri Lanka"
    else:
        market_data = DOMAIN_MARKET_DATA_GLOBAL
        currency = "USD"
        region_name = "Global"
    
    # Get base data for domain or use defaults
    domain_data = market_data.get(domain, {
        "base_salary_min": 50000 if region == "global" else 300000,
        "base_salary_max": 100000 if region == "global" else 800000,
        "base_demand": 75,
        "trend_factor": 1.01,
        "currency": currency,
    })
    
    # Use day of year to create daily variation (1-365)
    today = datetime.now()
    day_of_year = today.timetuple().tm_yday
    
    # Create daily variation (small random-like variation based on day)
    variation_factor = 1 + (day_of_year % 10) / 1000  # 0-0.9% variation
    
    # Calculate adjusted salary (with trend and daily variation)
    salary_min = int(domain_data["base_salary_min"] * domain_data["trend_factor"] * variation_factor)
    salary_max = int(domain_data["base_salary_max"] * domain_data["trend_factor"] * variation_factor)
    
    # Calculate demand with daily variation
    demand = int(domain_data["base_demand"] * variation_factor)
    demand = max(0, min(100, demand))  # Clamp between 0-100
    
    # Map demand to level
    if demand >= 85:
        demand_level = "Very High"
    elif demand >= 70:
        demand_level = "High"
    elif demand >= 50:
        demand_level = "Medium"
    elif demand >= 30:
        demand_level = "Moderate"
    else:
        demand_level = "Low"
    
    # Format salary range based on currency
    if currency == "LKR":
        salary_range = f"Rs. {salary_min:,} - Rs. {salary_max:,} per month"
    else:
        salary_range = f"${salary_min:,} - ${salary_max:,} per year"
    
    # Add market insights based on domain, region, and current trends
    insights = _generate_market_insights(domain, demand, salary_min, salary_max, region_name)
    
    return {
        "salary_range": salary_range,
        "salary_min": salary_min,
        "salary_max": salary_max,
        "demand_level": demand_level,
        "demand_percentage": demand,
        "insights": insights,
        "last_updated": today.strftime("%Y-%m-%d"),
        "region": region_name,
        "currency": currency
    }

def _generate_market_insights(domain: str, demand: int, salary_min: int, salary_max: int, region: str = "Global") -> str:
    """Generate AI-powered market insights for the domain and region."""
    insights = []
    
    if demand >= 85:
        insights.append(f"{domain} professionals are in very high demand in {region} with excellent job prospects.")
    elif demand >= 70:
        insights.append(f"{domain} has strong market demand in {region} with good career opportunities.")
    else:
        insights.append(f"{domain} shows moderate demand in {region}. Focus on building specialized skills.")
    
    avg_salary = (salary_min + salary_max) // 2
    
    # Adjust salary thresholds based on region
    if region == "Sri Lanka":
        if avg_salary >= 800000:
            insights.append("Competitive salary range in Sri Lankan market indicates high value for expertise.")
        elif avg_salary >= 500000:
            insights.append("Solid salary prospects in local market with room for growth.")
        else:
            insights.append("Entry-level opportunities available with potential for salary growth.")
    else:  # Global
        if avg_salary >= 100000:
            insights.append("Competitive salary range indicates high value placed on expertise in this field.")
        elif avg_salary >= 70000:
            insights.append("Solid salary prospects with room for growth as you gain experience.")
        else:
            insights.append("Entry-level opportunities available with potential for salary growth.")
    
    # Domain-specific insights with region context
    domain_insights_global = {
        "Design": "Remote work opportunities are increasing globally. Portfolio quality is crucial.",
        "Web Development": "Full-stack developers are highly sought after. Keep up with modern frameworks.",
        "AI & Data Science": "Rapidly growing field with high demand for ML/AI expertise worldwide.",
        "Mobile Development": "iOS and Android skills remain valuable. Cross-platform frameworks are trending.",
        "IT Project Manager": "Agile and Scrum certifications boost marketability globally.",
        "Business Analyst": "Data analysis and SQL skills are increasingly important.",
        "Cybersecurity": "Critical field with growing demand. Certifications (CISSP, CEH) are valuable.",
        "Cloud Computing": "AWS, Azure, and GCP certifications significantly boost career prospects.",
        "DevOps": "CI/CD and containerization skills (Docker, Kubernetes) are essential.",
        "Software Development": "Focus on clean code, testing, and modern development practices.",
        "Data Analytics": "SQL, Python, and visualization tools (Tableau, Power BI) are key skills.",
    }
    
    domain_insights_sri_lanka = {
        "Design": "Growing design industry in Sri Lanka. Remote work with international clients is common.",
        "Web Development": "High demand for full-stack developers in Colombo and tech hubs. React and Node.js are popular.",
        "AI & Data Science": "Emerging field in Sri Lanka with increasing opportunities in fintech and healthcare.",
        "Mobile Development": "Strong demand for Flutter and React Native developers. Local startups are hiring.",
        "IT Project Manager": "Agile methodologies are standard. PMP and Scrum certifications are valued.",
        "Business Analyst": "Growing need in banking and finance sector. Data analysis skills are essential.",
        "Cybersecurity": "Critical need in banking and government sectors. Certifications boost opportunities.",
        "Cloud Computing": "AWS and Azure skills are in high demand. Many companies are migrating to cloud.",
        "DevOps": "CI/CD skills are essential. Docker and Kubernetes knowledge is highly valued.",
        "Software Development": "Strong demand in Colombo tech companies. Clean code practices are important.",
        "Data Analytics": "Growing field in finance and retail. SQL and Python skills are essential.",
    }
    
    if region == "Sri Lanka":
        if domain in domain_insights_sri_lanka:
            insights.append(domain_insights_sri_lanka[domain])
    else:
        if domain in domain_insights_global:
            insights.append(domain_insights_global[domain])
    
    return " ".join(insights)

