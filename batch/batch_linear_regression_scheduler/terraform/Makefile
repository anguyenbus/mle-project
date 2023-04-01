# Copyright 2016 Philip G. Porada
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.ONESHELL:
.SHELL := /bin/bash
.PHONY: apply destroy destroy-target plan-destroy plan plan-target prep
VARS="vars/$(ACCOUNT)-$(REGION).tfvars"
DYNAMODB_TABLE="terraform-remote-state-lock"
KEY="batch-skill-extraction/$(BRAIN_ID)/terraform.tfstate"
WORKSPACE="$(ACCOUNT)-$(REGION)"
BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
GREEN=$(shell tput setaf 2)
YELLOW=$(shell tput setaf 3)
RESET=$(shell tput sgr0)

export TF_VAR_brain_id=$(BRAIN_ID)
export TF_VAR_brain_name=$(BRAIN_NAME)
export TF_VAR_customers=$(BATCH_SKILLS_EXTRACTION_CUSTOMERS)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

set-env:
	@if [ -z $(BRAIN_ID) ]; then \
		echo "$(BOLD)$(RED)BRAIN_ID was not set$(RESET)"; \
		ERROR=1; \
	 fi
	@if [ -z $(BRAIN_NAME) ]; then \
		echo "$(BOLD)$(RED)BRAIN_NAME was not set$(RESET)"; \
		ERROR=1; \
	 fi
	@if [ -z $(ACCOUNT) ]; then \
		echo "$(BOLD)$(RED)ACCOUNT was not set$(RESET)"; \
		ERROR=1; \
	 fi
	@if [ -z $(REGION) ]; then \
		echo "$(BOLD)$(RED)REGION was not set$(RESET)"; \
		ERROR=1; \
	 fi
	@if [ ! -z $${ERROR} ] && [ $${ERROR} -eq 1 ]; then \
		echo "$(BOLD)Example usage: \`ACCOUNT=development BRAIN_ID=001 BRAIN_NAME=brain-dev-nva-001 REGION=us-east-1 make plan\`$(RESET)"; \
		exit 1; \
	 fi
	@if [ ! -f "$(VARS)" ]; then \
		echo "$(BOLD)$(RED)Could not find variables file: $(VARS)$(RESET)"; \
		exit 1; \
	 fi

prep: set-env ## Prepare a new workspace (environment) if needed, configure the tfstate backend, update any modules, and switch to the workspace
	@echo "$(BOLD)Configuring the terraform backend$(RESET)"

	@echo "$(YELLOW)Account/Workspace:        $(WORKSPACE)$(RESET)"
	@echo "$(YELLOW)Backend Config Bucket:    $(ACCOUNT)-terraform-remote-state$(RESET)"
	@echo "$(YELLOW)Backend Config Key:       $(KEY)$(RESET)"
	@echo "$(YELLOW)Backend Config DynamoDB:  $(DYNAMODB_TABLE)$(RESET)"
	@echo "$(YELLOW)Vars:                     $(VARS)$(RESET)"

	@echo "$(YELLOW)BRAIN ID:                     	   $(TF_VAR_brain_id)$(RESET)"
	@echo "$(YELLOW)BRAIN_NAME:                		   $(TF_VAR_brain_name)$(RESET)"
	@echo "$(YELLOW)BATCH_SKILLS_EXTRACTION_CUSTOMERS: $(TF_VAR_customers)$(RESET)"

	@terraform init \
		-force-copy \
		-input=false \
		-get=true \
		-upgrade=true \
		-reconfigure \
		-backend=true \
		-backend-config="backend/$(ACCOUNT).backend" \
		-backend-config="key=$(KEY)" \
	  	-backend-config="acl=private"
	@echo "$(BOLD)Switching to workspace $(WORKSPACE)$(RESET)"
	@terraform workspace select $(WORKSPACE) || terraform workspace new $(WORKSPACE)

refresh: prep ## Show what terraform thinks it will do
	@terraform refresh \
		-lock=true \
		-input=false \
		-var-file="$(VARS)"

plan: prep ## Show what terraform thinks it will do
	@terraform plan \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)"

plan-out: prep ## Show what terraform thinks it will do
	@terraform plan \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)" \
		-lock=true \
		-out=tfplan

plan-target: prep ## Shows what a plan looks like for applying a specific resource
	@echo "$(YELLOW)$(BOLD)[INFO]   $(RESET)"; echo "Example to type for the following question: module.rds.aws_route53_record.rds-master"
	@read -p "PLAN target: " DATA && \
		terraform plan \
			-lock=true \
			-input=true \
			-refresh=true \
			-var-file="$(VARS)" \
			-target=$$DATA \
			-out=tfplan

plan-destroy: prep ## Creates a destruction plan.
	@terraform plan \
		-input=false \
		-refresh=true \
		-destroy \
		-var-file="$(VARS)" \
		-out=destroy.tfplan

apply: prep ## Have terraform do the things. This will cost money.
	@terraform apply \
		-lock=true \
		-input=false \
		-auto-approve \
		-refresh=true \
		-var-file="$(VARS)"

ci-apply: # no need to do init as we saved .terraform in CI from one plan step to apply another. We use tfplan as input
	@terraform apply \
		-input=false \
		-refresh=true \
		-lock=true \
		-auto-approve \
		-input=false \
		tfplan

ci-output: prep ## Export the output values in a json file
	@terraform output -json > terraform_output.json

destroy-plan: prep ## Destroy the things
	@terraform plan -destroy \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)"

destroy-ci: prep ## Destroy the things without asking for confirmation
	@terraform apply -destroy \
		-input=false \
		-auto-approve \
		-var-file="$(VARS)"

destroy: prep ## Destroy the things
	@terraform destroy \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file="$(VARS)"

destroy-target: prep ## Destroy a specific resource. Caution though, this destroys chained resources.
	@echo "$(YELLOW)$(BOLD)[INFO] Specifically destroy a piece of Terraform data.$(RESET)"; echo "Example to type for the following question: module.rds.aws_route53_record.rds-master"
	@read -p "Destroy target: " DATA && \
		terraform destroy \
		-lock=true \
		-input=false \
		-refresh=true \
		-var-file=$(VARS) \
		-target=$$DATA
