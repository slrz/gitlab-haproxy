require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::registry' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'backend execution' do
    shared_examples 'configuring registry haproxy' do
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes default recipe' do
        expect(chef_run).to include_recipe('gitlab-haproxy::default')
      end

      it 'creates the ssl cert files' do
        expect(chef_run).to create_file('/etc/haproxy/ssl/registry.pem').with(
          mode: '0600',
          content: /^MIICZTCCAc4C/
        )
        expect(chef_run.file('/etc/haproxy/ssl/registry.pem')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end

      it 'creates the template and runs correct notifications' do
        expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
          source: 'haproxy-registry.cfg.erb',
          mode: '0600',
          variables: { admin_password: 'this-is-a-test-password', use_internal: nil }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/registry.template'))
        }

        expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['api_address'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['registry']['peers']['servers']['fe-registry-01-lb-gstg'] = ['10.65.1.101', '32768']
    node.normal['gitlab-haproxy']['registry']['servers']['registry-01-sv-gstg'] = 'registry-01-sv-gstg.c.gitlab-staging-1.internal'
    node.normal['gitlab-haproxy']['registry']['custom_config'] = [
      'http-request deny deny_status 400 if is_bad',
    ]
  end
end
