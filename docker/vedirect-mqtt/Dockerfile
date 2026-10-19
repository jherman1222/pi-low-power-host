FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY bridge.py .

# Serial /dev nodes need dialout (compose sets group_add). Stay root for device open.
CMD ["python", "-u", "bridge.py"]
