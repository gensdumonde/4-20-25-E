FROM python:3.9-slim
WORKDIR /app
COPY script.py .
RUN pip install boto3 requests
CMD ["python", "script.py"]
