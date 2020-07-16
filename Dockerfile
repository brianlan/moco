FROM nvidia/cuda:10.0-base

RUN apt-get update && apt-get install -y --no-install-recommends curl
RUN apt-get install -y wget zip unzip

RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential wget git curl ca-certificates libjpeg-dev libpng-dev libgl1-mesa-dev libglib2.0-0 libsm6 libxrender1 libxext6

RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
  chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
      rm ~/miniconda.sh

#COPY .condarc /opt/conda/.condarc
#ENV CONDARC=/opt/conda/.condarc
RUN /opt/conda/bin/conda install -y python=3.7 conda-build pyyaml

ENV PATH=/opt/conda/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /opt/conda/bin/conda install -y pytorch=1.5.0 torchvision=0.6.0 cudatoolkit=10.2 -c pytorch

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list                                                                        
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get install -y apt-transport-https ca-certificates gnupg
RUN apt-get update && apt-get install -y google-cloud-sdk

# COPY requirements.txt .
# RUN pip install -r requirements.txt
ADD . /moco

ENV PYTHONPATH "${PYTONPATH}:/moco"
WORKDIR /moco
CMD [ "echo", "hello" ]

