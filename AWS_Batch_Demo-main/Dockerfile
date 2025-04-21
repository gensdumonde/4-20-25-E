FROM python:3.7.16

RUN apt-get update
RUN apt-get install unzip python3 pip -y
RUN pip install boto3

WORKDIR /app

COPY script.py .

CMD ["python", "script.py"]
