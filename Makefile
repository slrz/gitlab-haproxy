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
	find $(ROOT_DIR) -type f -name \*.rb -not -path "$(BUNDLE_PATH)/*" -exec bundle exec rubocop -S Gemfile Berksfile {} +

.PHONY: rspec
rspec:	### Run rspec tests
rspec:	check
	bundle exec rspec -f d

.PHONY: kitchen
kitchen:	### Run kitchen tests on DigitalOcean
ifeq ($(GITLAB_CI),)
	@# Locally, just fire up kitchen test, as we're not using ephemeral keys
	bundle exec kitchen test --concurrency=$(KITCHEN_TESTS) --destroy=always
else
	@# On CI, wrap kitchen test into setup/cleanup key routines

	@# First, check for DO access token env var
	@if [ -z "$$DIGITALOCEAN_ACCESS_TOKEN" ]; then \
		echo "Please set DIGITALOCEAN_ACCESS_TOKEN in CI/CD settings for this repo"; \
		exit 1; \
	fi

	@# Second, disable strict host checking and generate ephemeral key
	umask 0077 && \
		mkdir -p $$HOME/.ssh && \
		echo "$$ssh_config" > $$HOME/.ssh/config && \
		ssh-keygen -N '' -t ed25519 -C '' -f "$(KEY_FILE)"

	@# Third, register it on DO via API
	curl -sS --fail --header "Authorization: Bearer $$DIGITALOCEAN_ACCESS_TOKEN" \
		--request POST $(DO_KEYS_API) \
		--data-urlencode "name=$(KEY_NAME)" \
		--data-urlencode "public_key@$(KEY_FILE).pub" \
		> "$(KEY_FILE).json"		# and save it for later tasks

	@# Fourth, run kitchen test, wrapped in key setup/destroy routines
	export DIGITALOCEAN_SSH_KEY_IDS="$$(jq '.ssh_key.id' $(KEY_FILE).json)"; \
		bundle exec kitchen test --concurrency=$(KITCHEN_TESTS) --destroy=always; \
		r=$$?; \
		curl -sS --fail --header "Authorization: Bearer $$DIGITALOCEAN_ACCESS_TOKEN" \
			--request DELETE "$(DO_KEYS_API)/$$DIGITALOCEAN_SSH_KEY_IDS"; \
		exit $$r	# and passing kitchen error, so that we still fail pipeline if its not zero \
				# and if key deletion fails, Makefile will exit with error and tell us.
endif
