DOCKER_REGISTRY := docker.dragonfly.co.nz
IMAGE_NAME := tensor2tensor
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run $(INTERACT) --rm -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
INTERACT ?= 
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')

train:
	$(RUN) t2t-trainer \
		--generate_data \
		--data_dir=t2t_data \
		--output_dir=t2t_train/mnist \
		--problem=image_mnist \
		--model=shake_shake \
		--hparams_set=shake_shake_quick \
		--train_steps=1000 \
		--eval_steps=100

.PHONY: docker
docker:
	docker build --tag $(IMAGE):$(GIT_TAG) .
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
enter: INTERACT=-it
enter:
	$(RUN) bash

.PHONY: enter-root
enter-root: INTERACT=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash

.PHONY: inspect-variables
inspect-variables:
	@echo DOCKER_REGISTRY: $(DOCKER_REGISTRY)
	@echo IMAGE_NAME:      $(IMAGE_NAME)
	@echo IMAGE:           $(IMAGE)
	@echo RUN:             $(RUN)
	@echo UID:             $(UID)
	@echo GID:             $(GID)
	@echo INTERACT:        $(INTERACT)
	@echo GIT_TAG:         $(GIT_TAG)
