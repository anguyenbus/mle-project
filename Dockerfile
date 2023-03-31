FROM ubuntu:18.04

COPY requirements.txt /

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get clean && \
    apt-get install -y python3-minimal python3-pip python3-distutils python3-setuptools && \
    apt-get clean && \
    apt-get install -y curl jq nano && \
    pip3 install --upgrade pip && \
    pip3 install --requirement /requirements.txt && \
    echo 'alias python=python3' >> ~/.bashrc

WORKDIR /home/ubuntu/http_server/

ADD run.sh .
RUN chmod +x run.sh
EXPOSE 8000
EXPOSE 8001

CMD ["./run.sh"]
