#!/bin/bash

local_dataset_dir=$1
local_model_checkpoint_dir=$2
gs_dataset_zip_path=$3
gs_model_checkpoint_dir=$4
lr=$5
batch_size=$6
epochs=$7
schedule=$8

mkdir ${local_dataset_dir} -p
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

echo "start training.."
exec_str="
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
echo "finished training"
