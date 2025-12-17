FROM python:3.9-slim

WORKDIR /app

# 1. Copy dependencies
COPY requirements.txt .

# 2. Install GLOBALLY
RUN pip install --no-cache-dir -r requirements.txt

# 3. Create user
RUN useradd -m goldbeckuser

# 4. Copy app
COPY . .

# 5. Switch user & Run
USER goldbeckuser
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
