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
          variables: {
            admin_password: 'this-is-a-test-password',
            backend_servers: {
              'active' => {
                'canary_pages' => {},
                'pages' => { 'pages-01.stg.gitlab.com' => '127.0.0.1' },
              },
              'all' => {
                'canary_pages' => {},
                'pages' => { 'pages-01.stg.gitlab.com' => '127.0.0.1' },
              },
            },
          }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/pages.template'))
        }
        expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end
    end

    context 'With a canary backend' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          populate_node_properties(node)
          node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
          node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
          node.normal['gitlab-haproxy']['canary_pages']['default_weight'] = '5'
          node.normal['gitlab-haproxy']['canary_pages']['https_backend_listen_port'] = '443'
          node.normal['gitlab-haproxy']['canary_pages']['http_backend_listen_port'] = '80'
          node.normal['gitlab-haproxy']['pages']['backend']['servers']['default']['canary_pages']['pages-cny-01.stg.gitlab.com'] = '127.0.0.1'
        end.converge(described_recipe)
      end
      it 'creates the configuration with a canary server' do
        expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
          source: 'haproxy-pages.cfg.erb',
          mode: '0600',
          variables: {
            admin_password: 'this-is-a-test-password',
            backend_servers: {
              'active' => {
                'canary_pages' => { 'pages-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'pages' => { 'pages-01.stg.gitlab.com' => '127.0.0.1' },
              },
              'all' => {
                'canary_pages' => { 'pages-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'pages' => { 'pages-01.stg.gitlab.com' => '127.0.0.1' },
              },
            },
          }
        )

        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          # HTTPS servers in both backends
          # Note that for HTTPs we use the http port for the health check
          expect(content).to include('server pages-cny-01.stg.gitlab.com 127.0.0.1:443 weight 5 check inter 3s fastinter 1s downinter 5s fall 3 port 80')
          expect(content).to include('server pages-01.stg.gitlab.com 127.0.0.1:1443 weight 100 check inter 3s fastinter 1s downinter 5s fall 3 port 1080')
          # HTTP servers in both backends
          expect(content).to include('server pages-01.stg.gitlab.com 127.0.0.1:1080 weight 100 check inter 3s fastinter 1s downinter 5s fall 3')
          expect(content).to include('server pages-cny-01.stg.gitlab.com 127.0.0.1:80 weight 5 check inter 3s fastinter 1s downinter 5s fall 3')
        }
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
        expect(content).to include('hard-stop-after 5m')
      }
    end
  end

  context 'when domain blacklisting is enabled' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['pages']['enable_domain_blacklisting'] = true
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'includes the pages domain blacklisting options' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/pages-domain-blacklist.template'))
      }
    end
  end

  context 'when PROXY protocol is enabled' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['pages']['enable_https_proxyv2'] = true
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['canary_pages']['https_proxyv2_backend_listen_port'] = '443'
        node.normal['gitlab-haproxy']['pages']['backend']['servers']['default']['canary_pages']['pages-cny-01.stg.gitlab.com'] = '127.0.0.1'
      end.converge(described_recipe)
    end

    it 'includes the proxy-v2 option' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('server pages-01.stg.gitlab.com-proxyv2 127.0.0.1:2443 weight 100 check inter 3s fastinter 1s downinter 5s fall 3 port 1080 send-proxy-v2')
        expect(content).to include('server pages-cny-01.stg.gitlab.com-proxyv2 127.0.0.1:443 weight 0 check inter 3s fastinter 1s downinter 5s fall 3 port 1080 send-proxy-v2')
      }
    end
  end

  def populate_node_properties(node)
    node.normal['gitlab-haproxy']['pages']['backend']['servers']['default']['pages']['pages-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['pages']['peers']['servers']['fe-pages01.sv.gitlab.com'] = ['10.65.1.101', '32768']
    node.normal['gitlab-haproxy']['pages']['http_custom_config'] = [
      'http-request deny deny_status 400 if is_download',
    ]
    node.normal['gitlab-haproxy']['pages']['https_custom_config'] = [
      'http-request deny deny_status 500 if is_download',
    ]
  end
end
