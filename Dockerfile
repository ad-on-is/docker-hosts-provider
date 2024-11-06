FROM python:3
RUN apt update && apt install -y docker.io libglib2.0-dev libdbus-1-dev ca-certificates curl avahi-daemon

RUN pip install docker dbus-python 

COPY ./monitor.py /monitor.py

CMD ["python3", "/monitor.py"]