# FAST & FOOLPROOF DOCKERFILE
FROM python:3.9-slim

WORKDIR /app

# 1. Copy dependencies
COPY requirements.txt .

# 2. Install GLOBALLY (fixes the "ModuleNotFoundError")
RUN pip install --no-cache-dir -r requirements.txt

# 3. Create user
RUN useradd -m goldbeckuser

# 4. Copy app
COPY . .

# 5. Switch user & Run
USER goldbeckuser
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
# STAGE 2: Runtime Stage (The Shipping Box)
# We use a tiny "Distroless" or slim image for security
FROM python:3.9-slim

WORKDIR /app

# Security Best Practice: Create a non-root user
# We don't want the app running as root (Hacker protection)
RUN useradd -m goldbeckuser
USER goldbeckuser

# Copy installed packages from the builder stage
COPY --from=builder /root/.local /home/goldbeckuser/.local
COPY . .

# Update PATH to find the installed packages
ENV PATH=/home/goldbeckuser/.local/bin:$PATH

# Expose the port
EXPOSE 5000

# Run the app using Gunicorn (Production Application Server)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]