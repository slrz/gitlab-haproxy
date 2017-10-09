require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::frontend' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'backend execution' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new { |node|
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['api_address'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['frontend']['peers']['servers']['fe01.sv.gitlab.com'] = ['10.65.1.101', '32768']
        node.normal['gitlab-haproxy']['frontend']['api']['servers']['api01.stg.gitlab.com'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['frontend']['https_git']['servers']['git01.stg.gitlab.com'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['frontend']['registry']['servers']['registry01.be.gitlab.com'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['frontend']['ssh']['port'] = '2222'
        node.normal['gitlab-haproxy']['frontend']['ssh']['servers']['git01.stg.gitlab.com'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['frontend']['web']['servers']['web01.stg.gitlab.com'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['frontend']['websockets']['servers']['web01.stg.gitlab.com'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['frontend']['web']['content_security_policy'] = " default-src 'self';"
      }.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'Includes default recipe' do
      expect(chef_run).to include_recipe('gitlab-haproxy::default')
    end

    it 'creates the ssl cert files' do
      # gitlab
      expect(chef_run).to create_file('/etc/haproxy/ssl/gitlab.pem').with(
        mode: '0600',
        content: /^MIICZTCCAc4C/
      )
      expect(chef_run.file('/etc/haproxy/ssl/gitlab.pem')).to notify('execute[test-haproxy-config]').to(:run).delayed

      # ci
      expect(chef_run).to create_file('/etc/haproxy/ssl/ci.pem').with(
        mode: '0600',
        content: /^MIICZTCCAc4C/
      )
      expect(chef_run.file('/etc/haproxy/ssl/ci.pem')).to notify('execute[test-haproxy-config]').to(:run).delayed

      # registry
      expect(chef_run).to create_file('/etc/haproxy/ssl/registry.pem').with(
        mode: '0600',
        content: /^MIICZTCCAc4C/
      )
      expect(chef_run.file('/etc/haproxy/ssl/registry.pem')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end

    it 'creates the template and runs correct notifications' do
      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        source: 'haproxy-frontend.cfg.erb',
        mode: '0600',
        variables: { admin_password: 'this-is-a-test-password' }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end
end
