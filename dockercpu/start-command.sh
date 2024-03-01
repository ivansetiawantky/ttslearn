#!/bin/bash

source /home/jovyan/venv/bin/activate
jupyter-lab --ip=0.0.0.0 --port=8888 --no-browser --IdentityProvider.token='' --ServerApp.disable_check_xsrf=True --notebook-dir=/home/jovyan/work
