FROM python:3
RUN apt update && apt install -y docker.io

RUN pip install docker

COPY ./monitor.py /monitor.py

CMD ["python3", "/monitor.py"]