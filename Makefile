# Makefile for haproxy cookbook (please set the cookbook name)
# Copyright 2017, GitLab B.V.
# Licence MIT

# Variables
UNAME		:= $(shell uname -s)
ROOT_DIR	:= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUNDLE_PATH	?= $(ROOT_DIR)/.bundle
KITCHEN_YAML	?= .kitchen.do.yml
# just match from /^suites:$/ line to the end of file, and output count of all the '- name: blah' lines
# which is actually the count of our suites
KITCHEN_TESTS	?= $(shell awk '/^suites:$$/,0{$$2~/^name:/&&c++} END {print c}' $(KITCHEN_YAML))

# Ephemeral keys variables. Those are mostly for readability of the kitchen target where
# the ephemeral ssh keys are created, registered on DO, and destroyed after test
# Endpoint we connect to
DO_KEYS_API	:= https://api.digitalocean.com/v2/account/keys
# Name under which key will be visible in DO web interface for us to easily track those
# The key is living just for the duration of the pipeline run, and gets destroyed after
# rit finishes regardless of the build status.
KEY_NAME	:= CI@$$CI_PROJECT_NAMESPACE/$$CI_PROJECT_NAME, created by build job \#$$CI_JOB_ID
# Where the ephemeral key is saved by ssh-keygen. This is just for readability, as we can
# use "$(KEY_FILE).pub" later on to post public part of the key to DO API, and save the
# responce with the assigned ID to "$(KEY_FILE).json"
KEY_FILE	:= $$HOME/.ssh/id_ed25519

define ssh_config
Host *
	StrictHostKeyChecking	no
endef
export ssh_config

# this is godly
# https://news.ycombinator.com/item?id=11939200
.PHONY: help
help:	### This help screen. Keep it first target to be default
ifeq ($(UNAME), Linux)
	@grep -P '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
else
	@# this is not tested, but prepared in advance for you, Mac drivers
	@awk -F ':.*###' '$$0 ~ FS {printf "%15s%s\n", $$1 ":", $$2}' $(MAKEFILE_LIST) | grep -v '@awk' | sort
endif

# Targets
#
.PHONY: debug
debug:	### Debug Makefile itself
	@echo $(CURL)

.PHONY: gems
gems:	### Install latest versions of all gems
	rm -f Gemfile.lock
	bundle install --jobs $$(nproc) --clean --path $(BUNDLE_PATH)

.PHONY: check
check:	### Check style of all ruby files
	bundle exec cookstyle

.PHONY: rspec
rspec:	### Run rspec tests
	bundle exec rspec -f d

.PHONY: kitchen
kitchen:	### Run kitchen tests on DigitalOcean
ifeq ($(GITLAB_CI),)
	@# Locally, just fire up kitchen test, as we're not using ephemeral keys
	bundle exec kitchen test --concurrency=$(KITCHEN_TESTS) --destroy=always $(KITCHEN_SUITE)
else
	@# On CI, wrap kitchen test into setup/cleanup key routines

	@# Check for GCP service account
	@if [ -z "$$GCP_SERVICE_ACCOUNT" ]; then \
		echo "Please set GCP_SERVICE_ACCOUNT in CI/CD settings for this repo"; \
		exit 1; \
	fi

	@# Create the service account credential file
	mkdir -p $$HOME/.config/gcloud/ && \
		cp "$$GCP_SERVICE_ACCOUNT" $$HOME/.config/gcloud/application_default_credentials.json

	@# Disable strict host checking and generate ephemeral key
	umask 0077 && \
		mkdir -p $$HOME/.ssh && \
		echo "$$ssh_config" > $$HOME/.ssh/config && \
		ssh-keygen -N '' -t ed25519 -C '' -f "$(KEY_FILE)"

	@# Run kitchen test, wrapped in key setup/destroy routines
	export SSH_KEY="$(KEY_FILE)" \
		export KITCHEN_YAML=kitchen.ci.yml; \
		bundle exec kitchen test --destroy=always $(KITCHEN_PLATFORM); \
		r=$$?; \
		exit $$r	# and passing kitchen error, so that we still fail pipeline if its not zero \
				# and if key deletion fails, Makefile will exit with error and tell us.
endif
