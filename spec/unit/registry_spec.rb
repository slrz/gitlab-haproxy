require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::registry' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'using weights with canaries' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties_with_weights(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'creates the frontend template correctly with weights.' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('server gke-cny-registry 1.1.1.1:5000 weight 3 check inter 2s fastinter 1s downinter 5s fall 3 port 5001')
      }
    end
  end

  context 'with internal request routing' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['frontend']['canary_request_path']['path_list'] = ['/gitlab-com']
      end.converge(described_recipe)
    end

    it 'creates the frontend template correctly with internal request routing' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('use_backend canary_registry if is_canary_path !canary_disabled')
      }
    end

    it 'creates registry acls' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('acl is_canary_path path_beg -f /etc/haproxy/canary-request-paths.lst')
        expect(content).to include('acl is_canary_host hdr_beg(host) -i canary')
        expect(content).to include('acl is_canary req.cook(gitlab_canary) -m str -i true')
        expect(content).to include('acl canary_disabled req.cook(gitlab_canary) -m str -i false')
        expect(content).to include('acl no_be_srvs_canary_registry nbsrv(canary_registry) lt 1')
      }
    end

    it 'creates the request path regex lst file' do
      expect(chef_run).to render_file('/etc/haproxy/canary-request-paths.lst').with_content { |content|
        expect(content).to include('/gitlab-com')
      }
    end
  end

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
          variables: {
            admin_password: 'this-is-a-test-password',
            use_internal: nil,
            backend_servers: {
              'active' => {
                'canary_registry' => { 'gke-cny-registry' => '1.1.1.1' },
                'registry' => { 'registry-01-sv-gstg' => 'registry-01-sv-gstg.c.gitlab-staging-1.internal' },
              },
              'all' => {
                'canary_registry' => { 'gke-cny-registry' => '1.1.1.1' },
                'registry' => { 'registry-01-sv-gstg' => 'registry-01-sv-gstg.c.gitlab-staging-1.internal' },
              },
            },
            enforce_cf_origin_pull: false,
          }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/registry.template'))
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

      it_behaves_like 'configuring registry haproxy'
    end
  end

  context 'ssl_verify set to ssl verify none' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)

        node.normal['gitlab-haproxy']['registry']['ssl_verify'] = 'ssl verify none'
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'configures backends with ssl verify none' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('ssl verify none')
      }
    end
  end

  context 'using hard-stop' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['global']['hard-stop']['enable'] = true
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'includes the hard-stop timeout' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('hard-stop-after 10m')
      }
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['api_address'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['registry']['peers']['servers']['fe-registry-01-lb-gstg'] = ['10.65.1.101', '32768']
    node.normal['gitlab-haproxy']['registry']['servers']['registry-01-sv-gstg'] = 'registry-01-sv-gstg.c.gitlab-staging-1.internal'
    node.normal['gitlab-haproxy']['canary_registry']['servers']['gke-cny-registry'] = '1.1.1.1'
    node.normal['gitlab-haproxy']['registry']['custom_config'] = [
      'http-request deny deny_status 400 if is_bad',
    ]
  end

  def populate_node_properties_with_weights(node)
    populate_node_properties(node)
    node.normal['gitlab-haproxy']['canary_registry']['default_weight'] = '3'
  end
end
