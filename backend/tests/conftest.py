from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.core.security import create_access_token
from app.models.user import User
from main import app

# In-memory SQLite database for fast, isolated testing
SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="session", autouse=True)
def create_test_db():
    from unittest.mock import MagicMock
    from app.services.email_service import email_service
    # Mock real external email dispatch during test runs
    email_service.send_verification_otp = MagicMock(return_value=True)

    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session() -> Generator[Session]:
    connection = engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session: Session) -> Generator[TestClient]:
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def create_auth_headers(client: TestClient, email: str = "testuser@priora.app", full_name: str = "Test User") -> dict[str, str]:
    """Helper to register and return authenticated headers with verified status in tests."""
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!", "full_name": full_name},
    )
    db = next(client.app.dependency_overrides[get_db]())
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise RuntimeError(f"User {email} could not be created in test")
    user.is_email_verified = True
    db.commit()
    token = create_access_token(subject=str(user.id), email=user.email)
    return {"Authorization": f"Bearer {token}"}


def create_auth_headers_with_user_id(client: TestClient, email: str = "testuser@priora.app", full_name: str = "Test User") -> tuple[dict[str, str], str]:
    """Helper returning both authenticated headers and the user's UUID string."""
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!", "full_name": full_name},
    )
    db = next(client.app.dependency_overrides[get_db]())
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise RuntimeError(f"User {email} could not be created in test")
    user.is_email_verified = True
    db.commit()
    token = create_access_token(subject=str(user.id), email=user.email)
    return {"Authorization": f"Bearer {token}"}, str(user.id)
