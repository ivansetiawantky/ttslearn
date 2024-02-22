FROM ubuntu:23.04

#
# Timezone must be set before starting cron etc.
#
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV TZ="Asia/Tokyo"

# https://dev.to/0xbf/set-timezone-in-your-docker-image-d22
# https://qiita.com/jerrywdlee/items/d4468f076bdea236bf3b
# Must add below to correctly do cron at the specified timezone.
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       python3-venv \
       python3-dev \
       python3-pip \
       build-essential \
       libsamplerate0 \
       libsndfile1 \
       cmake \
       nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# It is better to use jovyan user to execute jupyter-lab.
RUN useradd --create-home --shell /bin/bash jovyan
USER jovyan
WORKDIR /home/jovyan

# venv directory must be owned by jovyan, so create venv with user jovyan (i.e., after USER jovyan layer)
RUN python3 -m venv /home/jovyan/venv
ENV PATH=/home/jovyan/venv/bin:$PATH

# Until here: BUILD AND TEST PYTHON3
# docker build [--no-cache] -t jupyterlab-ttslearn -f Dockerfile . [2>&1 | tee build.log]
# docker run --rm -ti jupyterlab-ttslearn whoami
# docker run --rm -ti jupyterlab-ttslearn bash -c 'which python3 && python3 --version && which pip3 && pip3 --version'
# docker run --rm -ti jupyterlab-ttslearn bash -c 'which python && python --version && which pip && pip --version'

# do pip3 install inside jovyan's venv (i.e. after ENV PATH=/home/jovyan/venv/bin:$PATH layer)
COPY ./resources/cpu.requirements.txt /tmp
RUN pip3 install --no-cache-dir -r /tmp/cpu.requirements.txt

COPY ./resources/requirements.txt /tmp
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# docker run --rm -ti jupyterlab-ttslearn bash -c 'pip3 freeze'

# Run the ubuntu system:
# docker run --rm -it --name ttslearncont -v `dirname $PWD`:/home/jovyan/work jupyterlab-ttslearn

# To execute another /bin/bash at the currently running container "ttslearncont":
# docker exec -it ttslearncont /bin/bash

# To execute another /bin/bash at the currently running container "ttslearncont", as root (for example to do `apt-get update`):
# docker exec -u root -it ttslearncont /bin/bash

# Inside the container do synthesis test (in python3 subshell):
# >>> from ttslearn.dnntts import DNNTTS
# >>> engine = DNNTTS()
# >>> wav, sr = engine.tts("これは日本語のテストです。")
# >>> from scipy.io.wavfile import write
# >>> write("example.wav", rate=sr, data=wav)
# >>> quit()

# How to run the jupyter-lab server from inside container.
#   (Preparation in host for persistent cache:
#   mkdir `pwd`/jovyan/dotcache/ttslearn && mkdir `pwd`/jovyan/dotjupyter)
# First, run the container:
# docker run -it --rm --name ttslearncont -v `dirname $PWD`:/home/jovyan/work -v `pwd`/jovyan/dotcache/ttslearn:/home/jovyan/.cache/ttslearn -v `pwd`/jovyan/dotjupyter:/home/jovyan/.jupyter -p 127.0.0.1:8889:8888 jupyterlab-ttslearn
# Second, from inside the container, execute this command:
# jupyter-lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --IdentityProvider.token='' --notebook-dir=/home/jovyan/work
# Third, from host, access http://localhost:8889
