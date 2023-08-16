.DEFAULT_GOAL := help

CLUSTER_NAME ?= tf-$(shell whoami)

.PHONY: init
init:
	terraform init -upgrade

.PHONY: create.public
create.public:
	terraform plan -out rosa.plan \
		-var "cluster_name=$(CLUSTER_NAME)" \
		-var "enable_private_link=false"
	terraform apply rosa.plan

.PHONY: create.privatelink
create.privatelink:
	terraform plan -out rosa.plan \
		-var "cluster_name=$(CLUSTER_NAME)" \
		-var "enable_private_link=true"
	terraform apply rosa.plan

.PHONY: create.pl
create.pl: privatelink

.PHONY: create.private-link
create.private-link: privatelink

.PHONY: create.private_link
create.private_link: privatelink

.PHONY: destroy.public
destroy.public:
	terraform destroy -var "cluster_name=$(CLUSTER_NAME)" \
	-var "enable_private_link=false" -auto-approve

.PHONY: destroy.privatelink
destroy.privatelink:
	terraform destroy -var "cluster_name=$(CLUSTER_NAME)" \
	-var "enable_private_link=true" -auto-approve


.PHONY: help
help:
	@echo "Usage:"
	@echo "  make create.[public|privatelink]"
	@echo "  make destroy.[public|privatelink]"
