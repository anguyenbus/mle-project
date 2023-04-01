FROM ubuntu:20.04

COPY requirements.txt /

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get clean && \
    apt-get install -y python3-minimal python3-pip python3-distutils python3-setuptools && \
    apt-get clean && \
    apt-get install -y curl jq nano && \
    pip3 install --upgrade pip

RUN pip3 install --requirement /requirements.txt && \
    echo 'alias python=python3' >> ~/.bashrc

RUN mkdir -p /home/ubuntu/http_server/
WORKDIR /home/ubuntu/http_server/
ADD http_server ./http_server/
ADD src ./src/
ADD api ./api/
ADD models ./models/
ADD manage.py .

ADD run.sh .

RUN chmod +x run.sh
EXPOSE 8000
EXPOSE 8001

CMD ["./run.sh"]
