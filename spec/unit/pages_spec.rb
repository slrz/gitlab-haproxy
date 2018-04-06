require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::pages' do
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
        expect(chef_run).to create_file('/etc/haproxy/ssl/pages.pem').with(
          mode: '0600',
          content: /^MIICZTCCAc4C/
        )
        expect(chef_run.file('/etc/haproxy/ssl/pages.pem')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end

      it 'creates the template and runs correct notifications' do
        expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
          source: 'haproxy-pages.cfg.erb',
          mode: '0600',
          variables: { admin_password: 'this-is-a-test-password' }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/pages.template'))
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

      it_behaves_like 'configuring pages haproxy'
    end

    context 'secrets in a backend specified by attribute' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          populate_node_properties(node)

          node.normal['gitlab-haproxy']['secrets'] = {
            'backend' => 'gkms',
            'path' => 'secrets',
            'key' => 'certs',
          }
        end.converge(described_recipe)
      end

      before do
        mock_secrets_path = 'test/integration/data_bags/secrets/certs.json'
        secrets = JSON.parse(File.read(mock_secrets_path))

        expect_any_instance_of(Chef::Recipe).to receive(:get_secrets)
          .with('gkms', 'secrets', 'certs').and_return(secrets)
      end

      it_behaves_like 'configuring pages haproxy'
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['pages']['servers']['web01.stg.gitlab.com'] = '127.0.0.1'
  end
end
