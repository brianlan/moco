sudo apt-get update
sudo apt-get install -y gcc

curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
sudo dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
sudo apt-get update
sudo apt-get install -y cuda-10-2
sudo apt-get install -y tmux zip unzip zsh htop

sudo wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
  chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
      rm ~/miniconda.sh

/opt/conda/bin/conda install -y python=3.7 conda-build pyyaml
export PATH=/opt/conda/bin:$PATH