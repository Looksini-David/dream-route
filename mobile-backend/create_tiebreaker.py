#!/usr/bin/env python3

from database import SessionLocal
from models import Quizzes
from datetime import datetime

def create_tiebreaker_quiz():
    db = SessionLocal()
    
    try:
        # Check if TIEBREAKER quiz exists
        existing = db.query(Quizzes).filter(Quizzes.quiz_id == 'TIEBREAKER').first()
        
        if existing:
            print("TIEBREAKER quiz entry already exists")
            return
        
        # Create TIEBREAKER quiz entry
        tiebreaker_quiz = Quizzes(
            quiz_id='TIEBREAKER',
            domain='Tiebreaker',
            title='Tiebreaker Quiz for Domain Resolution',
            created_at=datetime.now()
        )
        
        db.add(tiebreaker_quiz)
        db.commit()
        print("TIEBREAKER quiz entry created successfully")
        
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_tiebreaker_quiz()