COMPUTE ?= cpu
RUNTIME ?= runc
DOCKER_REGISTRY := docker.dragonfly.co.nz
IMAGE_NAME := tensor2tensor-$(COMPUTE)
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run --runtime=$(RUNTIME) $(DOCKER_ARGS) --rm -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE):latest
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?= 
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')

DATA_DIR ?= t2t_data/languagemodel_ptb10k
TRAIN_DIR ?= t2t_train/languagemodel_ptb10k
PROBLEM ?= languagemodel_ptb10k
MODEL ?= transformer
HPARAMS ?= transformer_small
TRAIN_STEPS ?= 1000
EVAL_STEPS ?= 100

BEAM_SIZE=4
ALPHA=0.6

# Generate data
data:
	$(RUN) t2t-datagen \
		--data_dir=$(DATA_DIR) \
		--tmp_dir=$(TMP_DIR) \
		--problem=$(PROBLEM)

train:
	$(RUN) t2t-trainer \
		--generate_data \
		--data_dir=$(DATA_DIR) \
		--output_dir=$(TRAIN_DIR) \
		--problem=$(PROBLEM) \
		--model=$(MODEL) \
		--hparams_set=$(HPARAMS) \
		--train_steps=$(TRAIN_STEPS) \
		--eval_steps=$(EVAL_STEPS) \

decode: decode_output.txt

decode_output.txt:
	$(RUN) t2t-decoder \
		--data_dir=$(DATA_DIR) \
		--problem=$(PROBLEM) \
		--model=$(MODEL) \
		--hparams_set=$(HPARAMS) \
		--output_dir=$(TRAIN_DIR) \
		--decode_hparams="beam_size=$(BEAM_SIZE),alpha=$(ALPHA)"

# Evaluate the BLEU score
# Note: Report this BLEU score in papers, not the internal approx_bleu metric.
score: decode_output.txt
	t2t-bleu --translation=decode_output.txt --reference=ref-translation.de

tensorboard:
	$(RUN) tensorboard --logdir=t2t_train/languagemodel_ptb10k --port 6006

.PHONY: docker
docker:
	eval $$(aws ecr get-login --no-include-email --region us-east-1 | sed 's|https://||')
	docker build --tag $(IMAGE):$(GIT_TAG) -f Dockerfile.$(COMPUTE) .
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: docker-push
docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

.PHONY: docker-pull
docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: enter
enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

.PHONY: enter-root
enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash

clean:
	rm -rf t2t_train/* t2t_data/*

.PHONY: inspect-variables
inspect-variables:
	@echo DOCKER_REGISTRY: $(DOCKER_REGISTRY)
	@echo IMAGE_NAME:      $(IMAGE_NAME)
	@echo IMAGE:           $(IMAGE)
	@echo RUN:             $(RUN)
	@echo UID:             $(UID)
	@echo GID:             $(GID)
	@echo DOCKER_ARGS:     $(DOCKER_ARGS)
	@echo GIT_TAG:         $(GIT_TAG)
