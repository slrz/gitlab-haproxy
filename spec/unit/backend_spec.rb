require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::backend' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'backend execution' do
    shared_examples 'configuring pages haproxy' do
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'Includes default recipe' do
        expect(chef_run).to include_recipe('gitlab-haproxy::default')
      end

      it 'creates ssl cert file' do
        expect(chef_run).to create_file('/etc/haproxy/ssl/gitlab.pem').with(
          mode: '0600',
          content: /^MIICZTCCAc4C/
        )
        expect(chef_run.file('/etc/haproxy/ssl/gitlab.pem')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end

      it 'creates the template and runs correct notifications' do
        expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
          source: 'haproxy-backend.cfg.erb',
          mode: '0600',
          variables: { admin_password: 'this-is-a-test-password' }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/backend.template'))
        }
        expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['backend']['rails']['servers']['rails01.be.gitlab.com'] = '127.0.0.1'
  end
end
