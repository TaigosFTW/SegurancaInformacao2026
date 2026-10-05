FROM python:3.12-alpine

WORKDIR /app
COPY index.html /app/index.html

EXPOSE 8000
CMD ["python", "-m", "http.server", "8000"]
