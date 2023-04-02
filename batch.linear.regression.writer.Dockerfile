FROM python:3.9

# upgrade pip
RUN pip install --upgrade pip
COPY batch/requirements.txt ./
RUN pip install -r requirements.txt

ENV HOME=/home/scheduler

RUN mkdir -p $HOME
RUN groupadd -r scheduler && \
    useradd -r -g scheduler -d $HOME -s /sbin/nologin -c "Docker image user" scheduler

WORKDIR $HOME

COPY batch/batch_linear_regression_scheduler/scheduler.py $HOME/
COPY batch/batch_linear_regression_scheduler/send_task_to_kinesis.py $HOME/

RUN chown -R scheduler:scheduler $HOME

USER scheduler
WORKDIR $HOME

ENTRYPOINT ["python", "-u", "scheduler.py"]
