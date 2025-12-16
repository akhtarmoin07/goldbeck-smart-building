# STAGE 1: Build Stage (The Factory)
# We use a full python image to compile things
FROM python:3.9-slim as builder

WORKDIR /app

# Copy dependency definition
COPY requirements.txt .

# Install dependencies into a local user directory
# --user installs to /root/.local, which we can copy later
RUN pip install --user --no-cache-dir -r requirements.txt

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