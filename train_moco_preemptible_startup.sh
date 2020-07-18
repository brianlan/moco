#!/bin/bash

local_dataset_dir=$1
local_model_checkpoint_dir=$2
gs_dataset_zip_path=$3
gs_model_checkpoint_dir=$4
lr=$5
batch_size=$6
epochs=$7
schedule=$8

# get params from google metadata
job_id=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/job_id -H "Metadata-Flavor: Google")
local_dataset_dir=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/local_dataset_dir -H "Metadata-Flavor: Google")
local_model_checkpoint_dir=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/local_model_checkpoint_dir -H "Metadata-Flavor: Google")
gs_dataset_zip_path=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gs_dataset_zip_path -H "Metadata-Flavor: Google")
gs_model_checkpoint_dir=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/gs_model_checkpoint_dir -H "Metadata-Flavor: Google")
lr=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/lr -H "Metadata-Flavor: Google")
batch_size=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/batch_size -H "Metadata-Flavor: Google")
epochs=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/epochs -H "Metadata-Flavor: Google")
schedule=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/schedule -H "Metadata-Flavor: Google")


shutdown_vm()
{
  echo "shutting vm down by setting size of instance group to 0"
  gcloud compute instance-groups managed resize $1 \
      --size 0 \
      --zone us-west1-a
  poweroff
}

# install environments
/opt/conda/bin/conda install -y pytorch=1.5.0 torchvision=0.6.0 cudatoolkit=10.2 -c pytorch
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install -y google-cloud-sdk
sudo gcloud auth configure-docker --quiet
sudo gcloud docker -- pull gcr.io/titanium-atlas-219621/moco:v0.0.6

# Prepare Data
if [ -d ${local_dataset_dir} ] 
then
  echo "directory ${local_dataset_dir} exists. clean it first."
  rm -rf ${local_dataset_dir}
fi

if [ -d ${local_model_checkpoint_dir} ] 
then
  echo "directory ${local_model_checkpoint_dir} exists. clean it first."
  rm -rf ${local_model_checkpoint_dir}
fi

echo "created dataset directory ${local_dataset_dir}" 
mkdir ${local_dataset_dir} -p
echo "created checkpoint directory ${local_dataset_dir}" 
mkdir ${local_model_checkpoint_dir} -p

local_dataset_zip_path=/tmp/$(basename ${gs_dataset_zip_path})

echo "downloading ${gs_dataset_zip_path} to ${local_dataset_zip_path}"
gsutil -m cp ${gs_dataset_zip_path} ${local_dataset_zip_path}
echo "finished downloading data"

echo "unzipping dataset ${local_dataset_zip_path} to ${local_dataset_dir}"
unzip ${local_dataset_zip_path} -d ${local_dataset_dir}
echo "finished unzipping dataset"

echo "downloading latest model checkpoint from ${gs_model_checkpoint_dir} to ${local_model_checkpoint_dir}"
gsutil -m cp ${gs_model_checkpoint_dir}/latest.pth.tar ${local_model_checkpoint_dir}
echo "finished downloading model checkpoints"

# Start Training
echo "start training.."
exec_str="
docker run --rm --name moco --ipc=host \
  -v /datadrive:/datadrive \
  -v /tmp:/tmp \
  gcr.io/titanium-atlas-219621/moco:v0.0.6 \
  python main_moco.py \
    -a resnet50 \
    --lr ${lr} \
    --batch-size ${batch_size} \
    --epochs ${epochs} \
    --schedule ${schedule} \
    --dist-url 'tcp://localhost:10001' \
    --multiprocessing-distributed \
    --world-size 1 --rank 0 \
    --mlp --moco-t 0.2 --aug-plus --cos \
    --local-checkpoint-dir ${local_model_checkpoint_dir} \
    --remote-checkpoint-dir ${gs_model_checkpoint_dir} \
    --resume ${local_model_checkpoint_dir}/latest.pth.tar \
    ${local_dataset_dir}
"
echo $exec_str
$($exec_str) 2>&1 | tee $job_id.log
echo "finished training"

# Shutdown the VM by setting size of instance group
shutdown_vm $job_id
