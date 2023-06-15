#
# Cookbook:: gitlab-haproxy
# Recipe:: logrotate
#
# Copyright:: (C) 2022 GitLab Inc.
#
# License: MIT
#

package 'logrotate'

# We may be able to ditch logrotate and rsyslog altogether
# if we update gitlab-fluentd to support reading logs from the systemd journal.
#
# rubocop:disable Chef/Modernize/CronDFileOrTemplate
cookbook_file '/etc/cron.hourly/logrotate' do
  source 'logrotate-cron'
  owner 'root'
  group 'root'
  mode '0755'
end

# It is not necessary to run logrotate daily if we're running it hourly (above)
# and if we do, we run the risk of collisions and logrotate running simultaneously.
# See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3955
file '/etc/cron.daily/logrotate' do
  action :delete
end

cookbook_file '/etc/logrotate.d/haproxy' do
  source 'logrotate-haproxy'
  owner 'root'
  group 'root'
  mode '0644'
end
