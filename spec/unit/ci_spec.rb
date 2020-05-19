require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::ci' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'backend execution' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['frontend']['canary_request_path']['path_list'] = ['/gitlab-com']
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'includes default recipe' do
      expect(chef_run).to include_recipe('gitlab-haproxy::default')
    end

    it 'creates the template and runs correct notifications' do
      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        source: 'haproxy-ci.cfg.erb',
        mode: '0600',
        variables: {
          admin_password: 'this-is-a-test-password',
          backend_servers: {
            'active' => {
              'api' => {
                'api02.stg.gitlab.com' => '127.0.0.1',
              },
              'canary_api' => {},
              'canary_https_git' => {},
              'https_git' => {
                'git02.stg.gitlab.com' => '127.0.0.1',
              },
            },
            'all' => {
              'api' => {
                'api02.stg.gitlab.com' => '127.0.0.1',
              },
              'canary_api' => {},
              'canary_https_git' => {},
              'https_git' => {
                'git02.stg.gitlab.com' => '127.0.0.1',
              },
            },
          },
        }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/ci.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['ci']['backend']['servers']['default']['https_git']['git02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['ci']['backend']['servers']['default']['api']['api02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['ci']['peers']['servers']['fe-registry-01-lb-gstg'] = ['10.65.1.101', '32768']
  end
end
