require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::camoproxy' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'backend execution' do
    shared_examples 'configuring camoproxy haproxy' do
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'Includes default recipe' do
        expect(chef_run).to include_recipe('gitlab-haproxy::default')
      end

      # In particular, we do NOT terminate SSL on these haproxy nodes, so creating
      # a cert would be bad
      it 'does not create ssl cert file' do
        expect(chef_run).to_not create_file('/etc/haproxy/ssl/camoproxy.pem')
      end

      it 'creates the template and runs correct notifications' do
        expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
          source: 'haproxy-camoproxy.cfg.erb',
          mode: '0600',
          variables: { admin_password: 'this-is-a-test-password' }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/camoproxy.template'))
        }
        expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end

      it 'creates deny list build script' do
        expect(chef_run).to create_cookbook_file('/usr/local/bin/build-camoproxy-deny-list.rb').with(
          mode: '0755'
        )
      end

      it 'notifies update deny list' do
        expect(chef_run.execute('update-camoproxy-deny-list')).to subscribe_to('execute[test-haproxy-config]').on(:run).before
      end
    end

    context 'secrets in Chef vault' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          populate_node_properties(node)

          node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
          node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        end.converge(described_recipe)
      end

      it_behaves_like 'configuring camoproxy haproxy'
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['camoproxy']['servers']['camoproxy-01-sv-gstg.c.gitlab-staging-1.internal'] = '127.0.0.1'
  end
end
