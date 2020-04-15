require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::altssh' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'backend execution' do
    shared_examples 'configuring altssh haproxy' do
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'Includes default recipe' do
        expect(chef_run).to include_recipe('gitlab-haproxy::default')
      end

      it 'creates the template and runs correct notifications' do
        expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
          source: 'haproxy-altssh.cfg.erb',
          mode: '0600',
          variables: {
            admin_password: 'this-is-a-test-password',
            backend_servers: {
              'active' => {
                'altssh' => { 'ssh01.stg.gitlab.com' => '127.0.0.1' },
              },
              'all' => {
                'altssh' => { 'ssh01.stg.gitlab.com' => '127.0.0.1' },
              },
            },
          }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/altssh.template'))
        }
        expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
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

      it_behaves_like 'configuring altssh haproxy'
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['altssh']['servers']['ssh01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['altssh']['custom_config'] = [
      'http-request deny deny_status 400 if is_download',
    ]
  end
end
