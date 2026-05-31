# Use the official Python 3.12 slim image — matches requires-python >=3.12 in pyproject.toml
FROM python:3.12-slim

# Pull the uv binary from its official distroless image; no pip install needed
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# All relative paths in the app (alembic.ini, ../frontend, ../specs) resolve from here
WORKDIR /app/backend

# Copy only the dependency manifest first so the next layer can be cached independently
COPY backend/pyproject.toml ./pyproject.toml

# Install runtime deps from pyproject.toml using stdlib tomllib (Python 3.11+)
# This layer is re-used on every rebuild as long as pyproject.toml is unchanged
RUN python3 -c "\
import tomllib, subprocess; \
deps = tomllib.load(open('pyproject.toml', 'rb'))['project']['dependencies']; \
subprocess.run(['uv', 'pip', 'install', '--system'] + deps, check=True)"

# Copy the FastAPI application package; only invalidates the cache when app/ source changes
COPY backend/app ./app

# Copy Alembic migration scripts; required by `alembic upgrade head` in CMD
COPY backend/alembic ./alembic

# Copy the Alembic config; tells Alembic where migrations live and how to reach the DB
COPY backend/alembic.ini ./alembic.ini

# Copy the idempotent seeder; run once at startup to populate demo tasks and users
COPY backend/seed.py ./seed.py

# Copy seed-data JSON one level up so seed.py resolves Path(__file__).parent.parent / "specs"
COPY specs/ ../specs/

# Copy the static frontend one level up; main.py mounts it via StaticFiles(directory="../frontend")
COPY frontend/ ../frontend/

# Document the default port; Cloud Run overrides this with the $PORT env var at runtime
EXPOSE 8080

# 1. Apply any pending DB migrations  2. Seed demo data (idempotent)  3. Start the server
# sh -c is required so the shell expands ${PORT:-8080} at container start time
CMD ["sh", "-c", "alembic upgrade head && python seed.py && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
