#!/bin/bash

GPUS_PER_NODE=8
NNODES=1
NODE_RANK=0
MASTER_ADDR=localhost
MASTER_PORT=6001

MODEL="/root/ld/ld_model_pretrained/minicpm-v" # or openbmb/MiniCPM-V-2, openbmb/MiniCPM-Llama3-V-2_5
# ATTENTION: specify the path to your training data, which should be a json file consisting of a list of conversations.
# See the section for finetuning in README for more information.
DATA="/root/ld/ld_dataset/pdf_cn_30k_search_train.json"
EVAL_DATA="/root/ld/ld_dataset/pdf_cn_30k_search_eval.json"
LLM_TYPE="minicpm" 

export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1 
# if use openbmb/MiniCPM-V-2, please set LLM_TYPE=minicpm
#if use openbmb/MiniCPM-Llama3-V-2_5, please set LLM_TYPE=llama3
DISTRIBUTED_ARGS="
    --nproc_per_node $GPUS_PER_NODE \
    --nnodes $NNODES \
    --node_rank $NODE_RANK \
    --master_addr $MASTER_ADDR \
    --master_port $MASTER_PORT
"
torchrun $DISTRIBUTED_ARGS finetune.py  \
    --model_name_or_path $MODEL \
    --llm_type $LLM_TYPE \
    --data_path $DATA \
    --eval_data_path $EVAL_DATA \
    --remove_unused_columns false \
    --label_names "labels" \
    --prediction_loss_only false \
    --bf16 false \
    --bf16_full_eval false \
    --fp16 true \
    --fp16_full_eval true \
    --do_train \
    --do_eval \
    --tune_vision false \
    --tune_llm false \
    --use_lora true \
    --model_max_length 700 \
    --max_slice_nums 9 \
    --max_steps 600 \
    --eval_steps 600 \
    --output_dir output/output_lora \
    --logging_dir output/output_lora \
    --logging_strategy "steps" \
    --per_device_train_batch_size 12 \
    --per_device_eval_batch_size 1 \
    --gradient_accumulation_steps 4 \
    --evaluation_strategy "steps" \
    --save_strategy "steps" \
    --save_steps 80 \
    --save_total_limit 3 \
    --learning_rate 1e-4 \
    --weight_decay 0.1 \
    --adam_beta2 0.95 \
    --warmup_ratio 0.01 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --gradient_checkpointing true \
    --deepspeed /root/ld/ld_project/pull_request/MiniCPM-V/finetune/ds_config_zero2.json \
    --report_to "tensorboard" # wandb
