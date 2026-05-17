# FastAPI Framework Patterns

Security and quality patterns specific to FastAPI applications.

---

## Security Patterns

### SQL Injection

| Pattern | Risk | Detection |
|---------|------|-----------|
| String formatting in query | Critical | `f"SELECT...{user_input}"` |
| Raw `text()` with concat | Critical | `text("SELECT..." + user_input)` |
| Cursor with `%` formatting | Critical | `cursor.execute(query % params)` |

**Safe Pattern:**
```python
# BAD
result = await db.execute(f"SELECT * FROM users WHERE id = {user_id}")

# GOOD - SQLModel / SQLAlchemy ORM
from sqlmodel import select
statement = select(User).where(User.id == user_id)
user = (await db.exec(statement)).first()

# GOOD - Parameterized text query
from sqlalchemy import text
await db.execute(text("SELECT * FROM users WHERE id = :id"), {"id": user_id})
```

### Input Validation (Pydantic-first)

FastAPI's primary security control is Pydantic validation. Skipping or weakening it is the most common defect class.

| Pattern | Risk | Detection |
|---------|------|-----------|
| `dict` body instead of Pydantic model | High | `body: dict = Body(...)` |
| `Any` type on body fields | High | `field: Any` |
| Missing field constraints (min/max length, regex) | Medium | `str` without `Field(...)` |
| `model_config = ConfigDict(extra="allow")` on user input | High | Allows unknown fields through |

**Safe Pattern:**
```python
# BAD
@app.post("/users")
async def create_user(body: dict):
    return await create(body)

# GOOD - Pydantic model with constraints
from pydantic import BaseModel, EmailStr, Field, ConfigDict

class UserCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")  # reject unknown fields
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    age: int = Field(ge=0, le=150)

@app.post("/users")
async def create_user(body: UserCreate):
    return await create(body)
```

### Authentication & Authorization

| Pattern | Risk | Detection |
|---------|------|-----------|
| Endpoint missing auth dependency | Critical | No `Depends(get_current_user)` |
| Hardcoded secret key | Critical | `SECRET_KEY = "dev"` |
| `algorithm="none"` on JWT | Critical | JWT decode without algorithm pin |
| Permissive scopes on protected route | High | `Security(...)` without `scopes=` |

**Safe Pattern:**
```python
from fastapi import Depends, HTTPException, status, Security
from fastapi.security import OAuth2PasswordBearer, SecurityScopes
from jose import JWTError, jwt
import os

SECRET_KEY = os.environ["JWT_SECRET_KEY"]  # NEVER hardcode
ALGORITHM = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token", scopes={"read": "Read", "admin": "Admin"})

async def get_current_user(
    security_scopes: SecurityScopes,
    token: str = Depends(oauth2_scheme),
) -> User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])  # algorithm pinned
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    user = await db_get_user(payload["sub"])
    for scope in security_scopes.scopes:
        if scope not in payload.get("scopes", []):
            raise HTTPException(status_code=403, detail="Insufficient scope")
    return user

# BAD - no auth
@app.get("/admin")
async def admin_panel():
    return {"users": await all_users()}

# GOOD - scoped auth required
@app.get("/admin")
async def admin_panel(user: User = Security(get_current_user, scopes=["admin"])):
    return {"users": await all_users()}
```

### CORS

```python
from fastapi.middleware.cors import CORSMiddleware

# BAD - permissive CORS in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,  # dangerous combo with allow_origins=*
    allow_methods=["*"],
    allow_headers=["*"],
)

# GOOD - explicit allowlist
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://app.example.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

### File Upload

```python
from fastapi import UploadFile, File, HTTPException
from pathlib import Path

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".txt"}
MAX_BYTES = 10 * 1024 * 1024  # 10 MB
UPLOAD_DIR = Path("/var/uploads")

# BAD - path traversal + no size cap + no type check
@app.post("/upload")
async def upload(file: UploadFile):
    content = await file.read()
    (UPLOAD_DIR / file.filename).write_bytes(content)

# GOOD
@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    suffix = Path(file.filename).suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Unsupported file type")
    content = await file.read(MAX_BYTES + 1)
    if len(content) > MAX_BYTES:
        raise HTTPException(status_code=413, detail="File too large")
    safe_name = f"{uuid.uuid4()}{suffix}"  # never trust client filename
    (UPLOAD_DIR / safe_name).write_bytes(content)
```

---

## Type Safety Patterns

### Response Models

```python
from pydantic import BaseModel

class UserPublic(BaseModel):
    id: int
    name: str
    email: str
    # NOTE: password_hash deliberately excluded

# BAD - leaks all User fields including password_hash
@app.get("/users/{user_id}")
async def get_user(user_id: int) -> User:
    return await db_get_user(user_id)

# GOOD - response_model filters output
@app.get("/users/{user_id}", response_model=UserPublic)
async def get_user(user_id: int) -> User:
    return await db_get_user(user_id)
```

### Path & Query Typing

```python
from fastapi import Path, Query
from typing import Annotated

# BAD - no type, no constraints
@app.get("/users/{user_id}")
async def get_user(user_id):
    ...

# GOOD - typed + constrained
@app.get("/users/{user_id}")
async def get_user(
    user_id: Annotated[int, Path(ge=1)],
    page: Annotated[int, Query(ge=1, le=1000)] = 1,
):
    ...
```

### Dependency Typing

```python
from typing import Annotated
from fastapi import Depends

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]

# Reusable typed dependencies — keeps signatures clean
@app.get("/profile")
async def profile(user: CurrentUser, db: DbSession):
    return await load_profile(db, user.id)
```

---

## Linting Patterns

### Async / Sync Consistency

```python
# BAD - sync DB call inside async endpoint blocks the event loop
@app.get("/users")
async def list_users():
    return db.query(User).all()  # sync SQLAlchemy

# GOOD - async DB driver throughout
@app.get("/users")
async def list_users(db: DbSession):
    result = await db.exec(select(User))
    return result.all()

# ALSO GOOD - sync endpoint when no async work needed (FastAPI runs in threadpool)
@app.get("/health")
def health():
    return {"ok": True}
```

### Router Organization

```python
# routers/users.py
from fastapi import APIRouter

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/")
async def list_users(): ...

@router.get("/{user_id}")
async def get_user(user_id: int): ...

# main.py
from routers import users, auth
app.include_router(users.router)
app.include_router(auth.router)
```

### Application Factory

```python
# BAD - global app with config baked in at import
app = FastAPI()
app.add_middleware(...)

# GOOD - factory enables per-test config + per-env wiring
def create_app(settings: Settings) -> FastAPI:
    app = FastAPI(title=settings.app_name)
    app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins)
    app.include_router(users.router)
    return app
```

---

## Coding Standards

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Router | snake_case | `users_router` |
| Endpoint function | snake_case | `get_user` |
| Pydantic model | PascalCase | `UserCreate`, `UserPublic` |
| Dependency function | snake_case | `get_current_user` |
| Settings class | PascalCase | `Settings` |

### File Organization

```
app/
  __init__.py
  main.py                  # create_app + entrypoint
  config.py                # Settings (pydantic-settings)
  dependencies.py          # shared Depends(...) functions
  routers/
    users.py
    auth.py
  models/                  # SQLModel / SQLAlchemy ORM
    user.py
  schemas/                 # Pydantic request/response models
    user.py
  services/                # business logic
    user_service.py
  db/
    session.py
```

---

## What to Skip

- OpenAPI / Swagger UI customization (`docs_url`, `redoc_url`)
- Uvicorn / Gunicorn worker tuning
- TestClient fixtures and `pytest-asyncio` setup
- CLI commands (Typer integration)
- Background task scheduling (Celery, RQ wiring)
