#!/usr/bin/env bash

# run service
nohup python3 -u manage.py runserver 0.0.0.0:8001 2>&1 &
python3 -u manage.py runserver --nothreading 0.0.0.0:8000
