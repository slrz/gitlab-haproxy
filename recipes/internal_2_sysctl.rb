#
# Cookbook:: gitlab-haproxy
# Recipe:: sysctls
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

# Some tuning based on
# https://medium.com/@pawilon/tuning-your-linux-kernel-and-haproxy-instance-for-high-loads-1a2105ea553e

# Allow more half-open connections to avoid SYN floods.
sysctl 'net.ipv4.tcp_max_syn_backlog' do
  value '10240'
end

# Increase maximum connections to allow connection bursts.
sysctl 'net.core.somaxconn' do
  value '65535'
end
