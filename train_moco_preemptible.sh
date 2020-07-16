#!/bin/bash

local_dataset_dir=$1
local_model_checkpoint_dir=$2
gs_dataset_dir=$3
gs_model_checkpoint_dir=$4
epochs=$5
schedule=$6

mkdir ${local_dataset_dir} -p
mkdir ${local_model_checkpoint_dir} -p

echo "downloading data from ${gs_dataset_dir} to ${local_dataset_dir}"
gsutil -m cp -r ${gs_dataset_dir}/* ${local_dataset_dir}
echo "finished downloading data"

echo "downloading latest model checkpoint from ${gs_model_checkpoint_dir} to ${local_model_checkpoint_dir}"
gsutil -m cp ${gs_model_checkpoint_dir}/latest.pth.tar ${local_model_checkpoint_dir}
echo "finished downloading model checkpoints"

echo "start training.."
python main_moco.py \
  -a resnet50 \
  --lr 0.03 \
  --batch-size 256 \
  --epochs ${epochs} \
  --schedule ${schedule} \
  --dist-url 'tcp://localhost:10001' 
  --multiprocessing-distributed \ 
  --world-size 1 --rank 0 \
  --mlp --moco-t 0.2 --aug-plus --cos \
  --local-checkpoint-dir ${local_model_checkpoint_dir} \
  --remote-checkpoint-dir ${gs_model_checkpoint_dir} \
  --resume ${local_model_checkpoint_dir}/latest.pth.tar \
  ${local_dataset_dir}
echo "finished training"
