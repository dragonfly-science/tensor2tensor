#! /bin/bash

set -ex

export RUN=
export OUTPUT_DIR=t2t_train/languagemodel_ptb10k
export PROBLEM=languagemodel_ptb10k
export MODEL=transformer
export HPARAMS=transformer_small
export TRAIN_STEPS=1000
export EVAL_STEPS=100


export DATA_DIR=$HOME/t2t_data/$PROBLEM
export TMP_DIR=$HOME/t2t_datagen/$PROBLEM
export TRAIN_DIR=$HOME/t2t_train/$PROBLEM/$MODEL-$HPARAMS

mkdir -p $DATA_DIR $TMP_DIR $TRAIN_DIR

make data
make tensorboard & make train

# See the decoder output
make decode_output.txt
cat decode_output.txt

make score

zip -r /output/t2t_datagen.zip TMP_DIR/*
zip -r /output/t2t_data.zip DATA_DIR/*
zip -r /output/t2t_train.zip TRAIN_DIR/*
