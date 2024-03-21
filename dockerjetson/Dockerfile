# Use l4t-cuda runtime as base image. nvidia-cuda and cuda-toolkit-11-4 is available here.
# Use multistage build to reduce the image size. See:
#    https://stackoverflow.com/questions/48561981/activate-python-virtualenv-in-dockerfile
#    https://deecode.net/?p=1999
#
# This dockerfile is for L4T r35.1.0, Jetpack 5.0.2-b231 t234
#
# Inside container: $ pip3 check
# Confirm that the image is OK by issuing below python3 lines inside container:
# >>> import torch
# >>> print(torch.cuda.is_available())
#
# Reference:
# https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-base
# https://repo.download.nvidia.com/jetson/
# https://gitlab.com/nvidia/container-images/l4t-jetpack
# https://gitlab.com/nvidia/container-images/l4t-base/-/blob/master/Dockerfile.cuda
# https://github.com/dusty-nv/jetson-containers/blob/master/Dockerfile.tensorflow
#
# FROM nvcr.io/nvidia/l4t-base:r35.1.0
FROM nvcr.io/nvidia/l4t-cuda:11.4.19-runtime as builder

USER root
WORKDIR /workdir

#
# Add apt repo as in:
# https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-base
# https://repo.download.nvidia.com/jetson/
#
RUN echo "deb https://repo.download.nvidia.com/jetson/t234 r35.1 main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install nvidia-cuda, cuda-toolkit-11-4, nvidia-cudnn8
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # nvidia-cuda \
    # cuda-toolkit-11-4 \
    nvidia-cudnn8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Update libraries, after ALL apt-get install are done.
RUN ldconfig

#
# Setup environment variables
#
ENV CUDA_HOME="/usr/local/cuda"
# ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

# It is better to use jovyan user to execute jupyter-lab, but cannot use jovyan in jetson
# RUN useradd --create-home --shell /bin/bash jovyan
# USER jovyan
# WORKDIR /home/jovyan

# venv directory must be owned by jovyan, so create venv with user jovyan (i.e., after USER jovyan layer)
# RUN python3 -m venv /home/jovyan/venv
# ENV PATH=/home/jovyan/venv/bin:$PATH

# First try with root
RUN python3 -m venv /venv
ENV PATH=/venv/bin:$PATH

#
# Install pytorch using wheel for Jetson
#
ARG PYTORCH_URL=https://developer.download.nvidia.com/compute/redist/jp/v502/pytorch/torch-1.13.0a0+936e9305.nv22.11-cp38-cp38-linux_aarch64.whl
ARG PYTORCH_WHL=torch-1.13.0a0+936e9305.nv22.11-cp38-cp38-linux_aarch64.whl

RUN wget --quiet --show-progress --progress=bar:force:noscroll --no-check-certificate ${PYTORCH_URL} -O ${PYTORCH_WHL} && \
    pip3 install --no-cache-dir --verbose ${PYTORCH_WHL} && \
    rm ${PYTORCH_WHL}

# Until here: BUILD AND TEST PYTHON3
# sudo docker build [--no-cache] -t jetson-ttslearn -f Dockerfile . [2>&1 | tee build.log]
# sudo docker run --rm -ti jetson-ttslearn whoami
# sudo docker run --rm -ti jetson-ttslearn bash -c 'which python3 && python3 --version && which pip3 && pip3 --version'

# do pip3 install inside root's /venv (i.e. after ENV PATH=/venv/bin:$PATH layer)
COPY ./resources/requirements.txt /tmp
RUN pip3 install --no-cache-dir wheel
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# sudo docker run --rm -ti jetson-ttslearn bash -c 'pip3 freeze'

# Run the ubuntu system:
# sudo docker run --rm -it --name jetsoncont --runtime nvidia -w /workdir -v `dirname $PWD`:/workdir jetson-ttslearn

# To execute another /bin/bash at the currently running container "jetsoncont":
# sudo docker exec -it jetsoncont /bin/bash

# To execute another /bin/bash at the currently running container "jetsoncont", as root (for example to do `apt-get update`):
# sudo docker exec -u root -it jetsoncont /bin/bash

# Inside the container do synthesis test (in python3 subshell):
# >>> from ttslearn.dnntts import DNNTTS
# >>> engine = DNNTTS()
# >>> wav, sr = engine.tts("これは日本語のテストです。")
# >>> from scipy.io.wavfile import write
# >>> write("example.wav", rate=sr, data=wav)
# >>> quit()

# How to run the jupyter-lab server from inside container.
#   (Preparation in host for persistent cache:
#   mkdir `pwd`/root/dotcache/ttslearn && mkdir `pwd`/root/dotjupyter)
# First, run the container:
# sudo docker run -it --rm --name jetsoncont --runtime nvidia --gpus all -w /workdir -v `dirname $PWD`:/workdir -v `pwd`/root/dotcache/ttslearn:/root/.cache/ttslearn -v `pwd`/root/dotjupyter:/root/.jupyter -p 8889:8888 jetson-ttslearn
#
# Second, from inside the container, execute this command:
# ldpreload=/venv/lib/python3.8/site-packages/scikit_learn.libs/libgomp-d22c30c5.so.1.0.0
# NVIDIA_VISIBLE_DEVICES=all NVIDIA_DRIVER_CAPABILITIES=all LD_PRELOAD=$ldpreload jupyter-lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --IdentityProvider.token='' --ServerApp.disable_check_xsrf=True --notebook-dir=/workdir
#
# Third, from host, access http://localhost:8889

FROM nvcr.io/nvidia/l4t-cuda:11.4.19-runtime as runner

USER root
WORKDIR /workdir

RUN echo "deb https://repo.download.nvidia.com/jetson/t234 r35.1 main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV TZ="Asia/Tokyo"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# No need to install python-wheel builder-tools (build-essential, etc.). Just install required libraries.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libsamplerate0 \
    libsndfile1 \
    nvidia-cudnn8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Update libraries, after ALL apt-get install are done.
RUN ldconfig

#
# Setup environment variables
#
ENV CUDA_HOME="/usr/local/cuda"
# ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

ENV PATH=/venv/bin:$PATH

# copy torch and modules in requirements.txt
COPY --from=builder /venv /venv

# builder is 6.24GB, and runner is 5.92GB
# Finally, can `sudo docker rmi nvcr.io/nvidia/l4t-cuda:11.4.19-runtime`
