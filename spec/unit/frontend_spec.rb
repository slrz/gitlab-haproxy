require 'spec_helper'
require 'chef-vault/test_fixtures'

describe 'gitlab-haproxy::frontend' do
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
        expect(content).to include('server web-cny-01.stg.gitlab.com 127.0.0.1:443 weight 5 check')
        expect(content).to include('server api01.stg.gitlab.com 127.0.0.1:443 weight 20')
        expect(content).to include('server git01.stg.gitlab.com 127.0.0.1:22 weight 30')
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
        expect(content).to include('hard-stop-after 30m')
      }
    end
  end

  context 'Content Security Policy' do
    context 'enabled CSP' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          populate_node_properties(node)
          node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
          node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        end.converge(described_recipe)
      end

      it 'includes the Content-Security-Policy header' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to include(%(rspadd Content-Security-Policy:\\ default-src\\ \\'self\\'))
        }
      end
    end

    context 'disabled CSP' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new do |node|
          populate_node_properties(node)
          node.normal['gitlab-haproxy']['frontend']['web']['content_security_policy_enabled'] = false
          node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
          node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        end.converge(described_recipe)
      end

      it 'omits the Content-Security-Policy header' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).not_to include('rspadd Content-Security Policy')
        }
      end
    end
  end

  context 'using multithreading' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['global']['multithreading']['enable'] = true
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'includes the multithreading options' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('nbproc 1')
        expect(content).to include('nbthread 1')
      }
    end
  end

  context 'using bind options' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['global']['ssl-default-bind-options'] = 'no-tlsv10 no-tlsv11'
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'creates the frontend template correctly with global bind options.' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('ssl-default-bind-options no-tlsv10 no-tlsv11')
      }
    end
  end

  context 'using root redirect option' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['frontend']['root_page_redirect']['enable'] = true
        node.normal['gitlab-haproxy']['frontend']['root_page_redirect']['url'] = 'https://example.com'
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'creates the redirect for requests without the _gitlab_session cookie' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('acl redirect_request_path path /')
        expect(content).to include('acl has_session_cookie req.cook(_gitlab_session) -m found')
        expect(content).to include('redirect location https://example.com code 301 if redirect_request_path !has_session_cookie')
      }
    end
  end

  context 'with internal request routing' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['frontend']['canary_request_path']['path_list'] = ['\/gitlab-com']
      end.converge(described_recipe)
    end

    it 'creates the frontend template correctly with internal request routing' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('use_backend canary_api if is_canary_path !canary_disabled')
        expect(content).to include('use_backend canary_web if is_canary_path !canary_disabled')
        expect(content).to include('use_backend canary_api if is_canary_path !canary_disabled')
      }
    end

    it 'creates the request path regex lst file' do
      expect(chef_run).to render_file('/etc/haproxy/canary-request-paths.lst').with_content { |content|
        expect(content).to include('\/gitlab-com')
      }
    end
  end

  context 'with asset proxy' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = true
        node.normal['gitlab-haproxy']['frontend']['asset_proxy']['host'] = 'gitlab-pre-assets.storage.googleapis.com'
      end.converge(described_recipe)
    end

    it 'creates the frontend template correctly with asset proxy' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('http-request set-header Host gitlab-pre-assets.storage.googleapis.com')
        expect(content).to include('use_backend asset_proxy if is_asset_path !no_be_srvs_asset_proxy')
      }
    end
  end

  context 'backend execution' do
    shared_examples 'configuring frontend haproxy' do
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it 'includes default recipe' do
        expect(chef_run).to include_recipe('gitlab-haproxy::default')
      end

      it 'creates the ssl cert files' do
        # gitlab
        expect(chef_run).to create_file('/etc/haproxy/ssl/gitlab.pem').with(
          mode: '0600',
          content: /^MIICZTCCAc4C/
        )
        expect(chef_run.file('/etc/haproxy/ssl/gitlab.pem')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end

      it 'creates the template and runs correct notifications' do
        expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
          source: 'haproxy-frontend.cfg.erb',
          mode: '0600',
          variables: {
            admin_password: 'this-is-a-test-password', use_internal: nil, use_canary: nil, enforce_cf_origin_pull: false, https_extra_bind_port: nil,
            backend_servers: {
              'active' => {
                'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
                'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
                'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
                'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
                'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              },
              'all' => {
                'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
                'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
                'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
                'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
                'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
                'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              },
            }
          }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/frontend.template'))
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

      it_behaves_like 'configuring frontend haproxy'
    end
  end

  context 'with a valid GCE zone but no zone configured servers' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'
      end.converge(described_recipe)
    end

    it 'creates the template and runs correct notifications' do
      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        source: 'haproxy-frontend.cfg.erb',
        mode: '0600',
        variables: {
          admin_password: 'this-is-a-test-password', use_internal: nil, use_canary: nil, enforce_cf_origin_pull: false, https_extra_bind_port: nil,
          backend_servers: {
            'active' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
            'all' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
          }
        }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties_zonal(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'
      end.converge(described_recipe)
    end

    it 'creates the template and runs correct notifications' do
      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        source: 'haproxy-frontend.cfg.erb',
        mode: '0600',
        variables: {
          admin_password: 'this-is-a-test-password', use_internal: nil, use_canary: nil, enforce_cf_origin_pull: false, https_extra_bind_port: nil,
          backend_servers: {
            'active' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
            'all' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
          }
        }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c, but without a canary server in the same zone' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties_zonal(node)
        # This switches the canary web node from us-east1-c to us-east1-d.
        # Because the LB is in us-east1-c this tests that web-cny-01 is
        # only marked as a backup.
        node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c'].delete('canary_web')
        node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_web']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'
      end.converge(described_recipe)
    end

    it 'creates the template and runs correct notifications' do
      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        source: 'haproxy-frontend.cfg.erb',
        mode: '0600',
        variables: {
          admin_password: 'this-is-a-test-password', use_internal: nil, use_canary: nil, enforce_cf_origin_pull: false, https_extra_bind_port: nil,
          backend_servers: {
            'active' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => {},
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
            'all' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
          }
        }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('server web-cny-01.stg.gitlab.com 127.0.0.1:443 check check-ssl inter 2s fastinter 1s downinter 5s fall 3 ssl verify none backup')
      }
      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c and backup servers' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties_zonal_backup(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'
      end.converge(described_recipe)
    end

    it 'creates the template and runs correct notifications' do
      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        source: 'haproxy-frontend.cfg.erb',
        mode: '0600',
        variables: {
          admin_password: 'this-is-a-test-password', use_internal: nil, use_canary: nil, enforce_cf_origin_pull: false, https_extra_bind_port: nil,
          backend_servers: {
            'active' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
            'all' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1', 'api02.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1', 'api-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1', 'git-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1', 'git-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1', 'web-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1', 'web-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1', 'git02.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1', 'git02.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1', 'web02.stg.gitlab.com' => '127.0.0.1' },
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1', 'web02.stg.gitlab.com' => '127.0.0.1' },
            },
          }
        }
      )

      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend-with-backup-servers.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c and no web servers' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties_zonal_missing_essential(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'
      end.converge(described_recipe)
    end

    it 'creates the template and runs correct notifications' do
      expect { chef_run }.to raise_error(RuntimeError, 'Essential backend web has zero active servers configured: {"api"=>{"api01.stg.gitlab.com"=>"127.0.0.1"}, "https_git"=>{"git01.stg.gitlab.com"=>"127.0.0.1"}, "ssh"=>{"git01.stg.gitlab.com"=>"127.0.0.1"}, "web"=>{}, "websockets"=>{"web01.stg.gitlab.com"=>"127.0.0.1"}, "canary_web"=>{"web-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_websockets"=>{"web-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_api"=>{"api-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_ssh"=>{"git-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_https_git"=>{"git-cny-01.stg.gitlab.com"=>"127.0.0.1"}}, aborting!')
    end
  end

  context 'with tcp-check' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = true
        node.normal['gitlab-haproxy']['frontend']['asset_proxy']['host'] = 'gitlab-pre-assets.storage.googleapis.com'
        node.normal['gitlab-haproxy']['frontend']['web']['tcp_check_enable'] = true
        node.normal['gitlab-haproxy']['frontend']['api']['tcp_check_enable'] = true
        node.normal['gitlab-haproxy']['frontend']['https_git']['tcp_check_enable'] = true
        node.normal['gitlab-haproxy']['frontend']['websockets']['tcp_check_enable'] = true
        node.normal['gitlab-haproxy']['frontend']['ssh']['tcp_check_enable'] = true
      end.converge(described_recipe)
    end

    it 'enables tcp check for web' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('server git01.stg.gitlab.com 127.0.0.1:22 check check-ssl port 443 verify none inter 2s fastinter 1s downinter 5s fall 3 check-ssl verify none')
        expect(content.scan(tcp_check).size).to eq(8)
      }
    end
  end

  context 'with systemd override' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
      end.converge(described_recipe)
    end

    it 'creates the systemd overrides' do
      expect(chef_run).to create_directory('/etc/haproxy/state')
      expect(chef_run).to create_directory('/etc/systemd/system/haproxy.service.d')
      expect(chef_run).to render_file('/etc/systemd/system/haproxy.service.d/override.conf').with_content { |content|
        expect(content).to include('ExecReload=/bin/bash -c')
        expect(content).to include('TimeoutStopSec=750')
        expect(content).to include('ExecStop=/usr/local/sbin/drain_haproxy.sh -w 600')
      }
    end
  end

  context 'with systemd override disabled' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['systemd_service_overrides']['enable'] = false
      end.converge(described_recipe)
    end

    it 'does not creates the systemd overrides' do
      expect(chef_run).not_to render_file('/etc/systemd/system/haproxy.service.d/override.conf')
    end
  end

  context 'with extra HTTPS bind port' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        populate_node_properties(node)
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['frontend']['https']['extra_bind_port'] = 11443
      end.converge(described_recipe)
    end

    it 'includes an extra bind directive with the supplied port' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('bind 0.0.0.0:11443 ssl crt /etc/haproxy/ssl/gitlab.pem')
      }
    end
  end

  def populate_node_properties_with_weights(node)
    populate_node_properties(node)
    node.normal['gitlab-haproxy']['frontend']['use_weights'] = true
    node.normal['gitlab-haproxy']['frontend']['web']['default_weight'] = '10'
    node.normal['gitlab-haproxy']['frontend']['api']['default_weight'] = '20'
    node.normal['gitlab-haproxy']['frontend']['ssh']['default_weight'] = '30'
    node.normal['gitlab-haproxy']['frontend']['https_git']['default_weight'] = '40'
    node.normal['gitlab-haproxy']['frontend']['websockets']['default_weight'] = '50'
    node.normal['gitlab-haproxy']['frontend']['canary_web']['default_weight'] = '1'
    node.normal['gitlab-haproxy']['frontend']['canary_api']['default_weight'] = '2'
    node.normal['gitlab-haproxy']['frontend']['canary_ssh']['default_weight'] = '3'
    node.normal['gitlab-haproxy']['frontend']['canary_https_git']['default_weight'] = '4'
    node.normal['gitlab-haproxy']['frontend']['canary_websockets']['default_weight'] = '5'
  end

  def populate_node_properties(node)
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
    node.normal['gitlab-haproxy']['frontend']['https']['custom_config'] = [
      'acl is_download path_reg -i (\/-\/archive\/).*[.](zip|tar|tar[.]gz|tar[.]bz2)$',
      'http-request deny deny_status 400 if is_download',
    ]
    node.normal['gitlab-haproxy']['frontend']['ssh']['custom_config'] = [
      'tcp-request connection deny',
    ]
    node.normal['gitlab-haproxy']['frontend']['api_rate_limit']['custom_config'] = [
      'http-request deny deny_status 400 if is_download',
    ]
    node.normal['gitlab-haproxy']['frontend']['canary_web']['servers']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['canary_api']['servers']['api-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['canary_ssh']['servers']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['canary_https_git']['servers']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['canary_websockets']['servers']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
  end

  def populate_node_properties_zonal(node)
    populate_node_properties(node)

    %w(api https_git registry ssh web websockets canary_web canary_api canary_ssh canary_https_git canary_websockets).each do |b|
      node.normal['gitlab-haproxy']['frontend'][b]['servers'] = {}
    end

    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['api']['api01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['https_git']['git01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['ssh']['git01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['web']['web01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['websockets']['web01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_web']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_websockets']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_api']['api-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_ssh']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_https_git']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
  end

  def populate_node_properties_zonal_backup(node)
    populate_node_properties_zonal(node)

    # These will be backup servers
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['api']['api02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['https_git']['git02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['ssh']['git02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['web']['web02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['websockets']['web02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_web']['web-cny-02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_websockets']['web-cny-02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_api']['api-cny-02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_ssh']['git-cny-02.stg.gitlab.com'] = '127.0.0.1'
    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_https_git']['git-cny-02.stg.gitlab.com'] = '127.0.0.1'
  end

  def populate_node_properties_zonal_missing_essential(node)
    populate_node_properties_zonal(node)

    node.normal['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['web'] = {}
  end

  def tcp_check
    <<-'CHK_WEB'
    option tcp-check
    tcp-check connect port 8083
    tcp-check send GET\ /readiness\ HTTP/1.0\r\n
    tcp-check send Host:\ gitlab.com\r\n
    tcp-check send \r\n
    tcp-check expect rstring HTTP/1\..\ 2..
    tcp-check connect port 443 ssl
    tcp-check send GET\ /-/health\ HTTP/1.0\r\n
    tcp-check send Host:\ gitlab.com\r\n
    tcp-check send \r\n
    tcp-check expect rstring HTTP/1\..\ 2..
    CHK_WEB
  end
end
