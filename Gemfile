source 'https://rubygems.org'

group :test do
  gem 'berkshelf', '~> 7.0'
  gem 'chef', '~> 14'
  gem 'chef-vault', '~> 3.0'
  gem 'chef-vault-testfixtures', '~> 3.0'
  gem 'chefspec'
  gem 'cookstyle'
  gem 'kitchen-digitalocean'
  gem 'kitchen-inspec'
  gem 'kitchen-vagrant'
  gem 'rubocop'
  gem 'test-kitchen'
  gem 'dbus-systemd'
end

group :ed25519 do
  gem 'bcrypt_pbkdf'
  gem 'rbnacl', '<5.0'
  gem 'rbnacl-libsodium'
end

# Need to use the git repo because we need some changes post 2.10.0 to work if docker isn't on localhost.
# Specifically https://github.com/test-kitchen/kitchen-docker/commit/a2b0511c64b19fe26c6c3a7720602bc7b28195bd#diff-a8e133f39d8e85fdff3a1275e8005071a44346c7fc8fec7064b1cbffb0a7b469R40
# Can revert to gem if/when that gets released
gem 'kitchen-docker', git: 'https://github.com/test-kitchen/kitchen-docker/'
