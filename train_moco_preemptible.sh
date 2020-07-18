#!/bin/bash
#========================================================================
# This creates the template for model training with preemptible instance.

# Created by: Yang Fu
# Version: 1.0
#=========================================================================


### Metadata specification
local_dataset_dir=$1
local_model_checkpoint_dir=$2
gs_dataset_zip_path=$3
gs_model_checkpoint_dir=$4
lr=$5
batch_size=$6
epochs=$7
schedule=$8

dataset=$(basename $local_dataset_dir)
datehour=$(date +"%H%M")
job_id=$dataset-$datehour-$lr-$batch_size-$epochs-$schedule

### Creates an instance template for specific training jobs
gcloud beta compute instance-templates create $job_id \
    --machine-type n1-standard-16 \
    --boot-disk-size 500GB \
    --accelerator type=nvidia-tesla-v100,count=2 \
    --image ubuntu1804-auto --image-project titanium-atlas-219621 \
    --maintenance-policy TERMINATE --restart-on-failure \
    --metadata ^___^local_dataset_dir="$local_dataset_dir"___local_model_checkpoint_dir="$local_model_checkpoint_dir"___gs_dataset_zip_path="$gs_dataset_zip_path"___gs_model_checkpoint_dir="$gs_model_checkpoint_dir"___lr="$lr"___batch_size="$batch_size"___epochs="$epochs"___schedule="$schedule" \
    --metadata-from-file startup-script=./train_moco_preemptible.sh \
    --scopes https://www.googleapis.com/auth/cloud-platform \
    --preemptible \
    --boot-disk-type=pd-ssd \
    --network-tier=STANDARD

### Start VM
gcloud compute instance-groups managed create $job_id \
	--base-instance-name $job_id \
	--size 1 \
	--template $job_id \
	--zone us-west1-a
