DOCKER_REGISTRY := 121565642659.dkr.ecr.us-east-1.amazonaws.com/waha-tuhi
IMAGE_NAME := tensor2tensor-$(COMPUTE)
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run --runtime $(RUNTIME) $(DOCKER_ARGS) --rm -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE):latest
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?= 
COMPUTE ?= cpu
RUNTIME ?= runc
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')

train:
	$(RUN) t2t-trainer \
		--generate_data \
		--data_dir=t2t_data/languagemodel_ptb10k \
		--output_dir=t2t_train/languagemodel_ptb10k \
		--problem=languagemodel_ptb10k \
		--model=transformer \
		--hparams_set=transformer_small \
		--train_steps=1000 \
		--eval_steps=100

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
