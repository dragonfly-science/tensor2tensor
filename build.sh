#! /bin/bash

set -ex

export RUN=

make train

zip /output/t2t_data.zip t2t_data/*
zip /output/t2t_train.zip t2t_train/*
