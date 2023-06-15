#
# Cookbook:: gitlab-haproxy
# Recipe:: frontend
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#
# This recipe is an alias for main. It is kept for compatibility with old fe-* roles.
# TODO: After the following are completed closed, this recipe should be removed.
#
#   https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/839
#   https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1009
#   https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/23687
#

include_recipe 'gitlab-haproxy::main'
