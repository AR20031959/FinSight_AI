# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.schemas import UserCreate, UserLogin, TokenResponse, UserResponse
from app.auth import get_password_hash, verify_password, create_access_token, log_audit_event, get_current_user

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        log_audit_event(db, None, "FAILED_REGISTER", resource=user_in.email, details="Email already registered")
        raise HTTPException(status_code=400, detail="Email is already registered")

    user_role = (user_in.role or "user").lower()
    if user_role not in ["user", "enterprise"]:
        user_role = "user"

    user = User(
        email=user_in.email,
        full_name=user_in.full_name,
        role=user_role,
        hashed_password=get_password_hash(user_in.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    log_audit_event(db, user.id, "REGISTER", resource=user.email, details=f"Registered with role {user.role}")

    token = create_access_token({"sub": user.email, "role": user.role})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))

@router.post("/login", response_model=TokenResponse)
def login(user_in: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_in.email).first()
    if not user or not verify_password(user_in.password, user.hashed_password):
        log_audit_event(db, None, "FAILED_LOGIN", resource=user_in.email, details="Invalid credentials")
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # REQUIREMENT 2: Selected role must match user's actual database role
    selected_role = (user_in.role or "user").lower()
    db_role = (user.role or "user").lower()

    if selected_role != db_role:
        log_audit_event(
            db, 
            user.id, 
            "FAILED_LOGIN_ROLE_MISMATCH", 
            resource=user.email, 
            details=f"Selected role '{selected_role}' does not match registered role '{db_role}'"
        )
        raise HTTPException(
            status_code=400, 
            detail=f"Role mismatch. Selected login role is '{selected_role.capitalize()}', but your account is registered as '{db_role.capitalize()}'."
        )

    log_audit_event(db, user.id, "LOGIN", resource=user.email, details=f"Logged in with role {user.role}")
    token = create_access_token({"sub": user.email, "role": user.role})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)


