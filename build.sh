#! /bin/bash

set -ex

export RUN=

make tensorboard & make train

zip -r /output/t2t_data.zip t2t_data/languagemodel_ptb10k/*
zip -r /output/t2t_train.zip t2t_train/languagemodel_ptb10k/*
