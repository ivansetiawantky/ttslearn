#!/bin/bash

source /venv/bin/activate
jupyter-lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --IdentityProvider.token='' --ServerApp.disable_check_xsrf=True --notebook-dir=/workdir
