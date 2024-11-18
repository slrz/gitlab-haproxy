#
# Cookbook:: gitlab-haproxy
# Recipe:: kitchen_update_ca_certs
#
# Copyright:: (C) 2024 GitLab Inc.
#
# License: MIT
#
# We only use this recipe in the kitchen tests
#
# This ensures we use the system store for Chef.
#
# Otherwise newer Let's Encrypt certificates will not work within chef
# when using remote_file resources.

# update packages
apt_update 'update packages'

# upgrade ca-certificates
apt_package 'ca-certificates' do
  action :upgrade
end

link '/opt/chef' do
  to '/opt/cinc'
  only_if { ::File.directory? '/opt/cinc' }
  not_if { ::File.directory? '/opt/chef' }
end

# Use the system CA certificates
link '/opt/chef/embedded/ssl/cert.pem' do
  to '/etc/ssl/certs/ca-certificates.crt'
  only_if do
    ::File.exist?('/etc/ssl/certs/ca-certificates.crt')
  end
end
