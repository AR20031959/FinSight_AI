import datetime
from typing import Optional, List, Callable
# pyrefly: ignore [missing-import]
from fastapi import Depends, HTTPException, status, Request
# pyrefly: ignore [missing-import]
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.config import settings
from app.database import get_db
from app.models import User, Enterprise, EnterpriseMember, AuditLog

# pyrefly: ignore [missing-import]
import bcrypt

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def create_access_token(data: dict, expires_delta: Optional[datetime.timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.datetime.utcnow() + expires_delta
    else:
        expire = datetime.datetime.utcnow() + datetime.timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate authentication credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    user = db.query(User).filter(User.email == email).first()
    if user is None or not user.is_active:
        raise credentials_exception
    return user

def require_role(allowed_roles: List[str]):
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        user_role = (current_user.role or "user").lower()
        allowed = [r.lower() for r in allowed_roles]
        if user_role not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: Required role in {allowed_roles}, but current user role is '{current_user.role}'."
            )
        return current_user
    return role_checker

def verify_enterprise_membership(db: Session, enterprise_user_id: int, member_user_id: int) -> bool:
    """
    Checks if member_user_id belongs to any enterprise that enterprise_user_id is a member/admin of.
    """
    if enterprise_user_id == member_user_id:
        return True

    # Find enterprises enterprise_user_id belongs to
    ent_ids = db.query(EnterpriseMember.enterprise_id).filter(
        EnterpriseMember.user_id == enterprise_user_id,
        EnterpriseMember.status == "active"
    ).all()
    
    if not ent_ids:
        return False

    ent_id_list = [e[0] for e in ent_ids]
    
    # Check if target member_user_id is in any of those enterprises
    match = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id.in_(ent_id_list),
        EnterpriseMember.user_id == member_user_id,
        EnterpriseMember.status == "active"
    ).first()

    return match is not None

def log_audit_event(
    db: Session, 
    user_id: Optional[int], 
    action: str, 
    resource: Optional[str] = None, 
    ip_address: Optional[str] = None, 
    details: Optional[str] = None
):
    try:
        log_entry = AuditLog(
            user_id=user_id,
            action=action,
            resource=resource,
            ip_address=ip_address,
            details=details
        )
        db.add(log_entry)
        db.commit()
    except Exception:
        db.rollback()



