require 'spec_helper'
require 'chef-vault/test_fixtures'

def populate_node_properties
  normal_attributes['gitlab-haproxy']['chef_vault'] = 'secrets'
  normal_attributes['gitlab-haproxy']['chef_vault_item'] = 'certs'
  normal_attributes['gitlab-haproxy']['api_address'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['peers']['servers']['fe01.sv.gitlab.com'] = ['10.65.1.101', '32768']
  normal_attributes['gitlab-haproxy']['frontend']['api']['servers']['api01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['https_git']['servers']['git01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['registry']['servers']['registry01.be.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['ssh']['port'] = '2222'
  normal_attributes['gitlab-haproxy']['frontend']['ssh']['servers']['git01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['web']['servers']['web01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['websockets']['servers']['web01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy_enabled'] = true
  normal_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy'] = " default-src 'self';"
  normal_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy_report_only_enabled'] = true
  normal_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy_report_only'] = " default-src 'self';"
  normal_attributes['gitlab-haproxy']['frontend']['https']['custom_config'] = [
    'acl is_download path_reg -i (\/-\/archive\/).*[.](zip|tar|tar[.]gz|tar[.]bz2)$',
    'http-request deny deny_status 400 if is_download',
  ]
  normal_attributes['gitlab-haproxy']['frontend']['ssh']['custom_config'] = [
    'tcp-request connection deny',
  ]
  normal_attributes['gitlab-haproxy']['frontend']['api_rate_limit']['custom_config'] = [
    'http-request deny deny_status 400 if is_download',
  ]
  normal_attributes['gitlab-haproxy']['frontend']['canary_web']['servers']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['canary_api']['servers']['api-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['canary_ssh']['servers']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['canary_https_git']['servers']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['canary_websockets']['servers']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
end

def populate_node_properties_with_weights
  populate_node_properties
  normal_attributes['gitlab-haproxy']['frontend']['web']['default_weight'] = '10'
  normal_attributes['gitlab-haproxy']['frontend']['api']['default_weight'] = '20'
  normal_attributes['gitlab-haproxy']['frontend']['ssh']['default_weight'] = '30'
  normal_attributes['gitlab-haproxy']['frontend']['https_git']['default_weight'] = '40'
  normal_attributes['gitlab-haproxy']['frontend']['websockets']['default_weight'] = '50'
  normal_attributes['gitlab-haproxy']['frontend']['canary_web']['default_weight'] = '1'
  normal_attributes['gitlab-haproxy']['frontend']['canary_api']['default_weight'] = '2'
  normal_attributes['gitlab-haproxy']['frontend']['canary_ssh']['default_weight'] = '3'
  normal_attributes['gitlab-haproxy']['frontend']['canary_https_git']['default_weight'] = '4'
  normal_attributes['gitlab-haproxy']['frontend']['canary_websockets']['default_weight'] = '5'
end

def populate_node_properties_zonal
  populate_node_properties

  %w(api https_git registry ssh web websockets canary_web canary_api canary_ssh canary_https_git canary_websockets).each do |b|
    normal_attributes['gitlab-haproxy']['frontend'][b]['servers'] = {}
  end

  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['api']['api01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['https_git']['git01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['ssh']['git01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['web']['web01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_web']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_websockets']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_api']['api-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_ssh']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['canary_https_git']['git-cny-01.stg.gitlab.com'] = '127.0.0.1'
  # If the zone is set to `default` it will be included by default
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['default']['websockets']['web01.stg.gitlab.com'] = '127.0.0.1'
end

def populate_node_properties_zonal_backup
  populate_node_properties_zonal

  # These will be backup servers
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['api']['api02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['https_git']['git02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['ssh']['git02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['web']['web02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['websockets']['web02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_web']['web-cny-02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_websockets']['web-cny-02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_api']['api-cny-02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_ssh']['git-cny-02.stg.gitlab.com'] = '127.0.0.1'
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_https_git']['git-cny-02.stg.gitlab.com'] = '127.0.0.1'
  # This is a default server which should not be marked as a backup
  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['default']['canary_ssh']['git-cny-default-server'] = '127.0.0.1'
end

def populate_node_properties_zonal_missing_essential
  populate_node_properties_zonal

  normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c']['web'] = {}
end

def parse_config(content)
  config = Hash.new { |h, k| h[k] = [] }
  section = nil

  content.each_line do |line|
    line.strip!

    if line.start_with?('#') || line.empty?
      # skip
    elsif (match_data = /^(global|defaults.*|listen .*|frontend .*|backend .*|peers .*|mailers .*)$/.match(line))
      section = match_data[1]
    else
      config[section] << line
    end
  end

  config
end

describe 'gitlab-haproxy::frontend' do
  include ChefVault::TestFixtures.rspec_shared_context

  context 'using weights with canaries' do
    populate_node_properties_with_weights

    it 'creates the frontend template correctly with weights.' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('server web-cny-01.stg.gitlab.com 127.0.0.1:443 weight 5 check')
        expect(content).to include('server api01.stg.gitlab.com 127.0.0.1:443 weight 20')
        expect(content).to include('server git01.stg.gitlab.com 127.0.0.1:22 weight 30')
      }
    end
  end

  context 'using hard-stop' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['global']['hard-stop']['enable'] = true

    it 'includes the hard-stop timeout' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('hard-stop-after 5m')
      }
    end
  end

  context 'Content Security Policy Report Only' do
    populate_node_properties
    context 'enabled CSPRO' do
      it 'includes the Content-Security-Policy-Report-Only header' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to include(%(rspadd Content-Security-Policy-Report-Only:\\ default-src\\ \\'self\\'))
        }
      end
    end

    context 'disabled CSPRO' do
      override_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy_report_only_enabled'] = false

      it 'omits the Content-Security-Policy-Report-Only header' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).not_to include('rspadd Content-Security-Policy-Report-Only:')
        }
      end
    end
  end

  context 'Content Security Policy' do
    populate_node_properties
    context 'enabled CSP' do
      it 'includes the Content-Security-Policy header' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to include(%(rspadd Content-Security-Policy:\\ default-src\\ \\'self\\'))
        }
      end
    end

    context 'disabled CSP' do
      override_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy_enabled'] = false
      override_attributes['gitlab-haproxy']['frontend']['canary_web']['content_security_policy_enabled'] = false
      it 'omits the Content-Security-Policy header' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).not_to include('rspadd Content-Security-Policy:')
        }
      end
    end
  end

  context 'using bind options' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['global']['ssl-default-bind-options'] = 'no-sslv3 no-tlsv10 no-tlsv11'

    it 'creates the frontend template correctly with global bind options.' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11')
      }
    end
  end

  context 'using root redirect option' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['frontend']['root_page_redirect']['enable'] = true
    normal_attributes['gitlab-haproxy']['frontend']['root_page_redirect']['url'] = 'https://example.com'

    it 'creates the redirect for requests without the _gitlab_session cookie' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('acl redirect_request_path path /')
        expect(content).to include('acl has_session_cookie req.cook(_gitlab_session) -m found')
        expect(content).to include('redirect location https://example.com code 301 if redirect_request_path !has_session_cookie')
      }
    end
  end

  context 'with internal request routing' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['frontend']['canary_request_path']['path_list'] = ['\/gitlab-com']

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
    populate_node_properties
    normal_attributes['cloud']['provider'] = 'gce'

    it 'creates the frontend template correctly with asset proxy' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        # Default env is _default; replacing that is challenging, so allow this technically invalid hostname for the purposes of testing
        expect(content).to include('http-request set-header Host gitlab-_default-assets.storage.googleapis.com')
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
                'web_k8s' => {},
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
                'web_k8s' => {},
                'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              },
            },
            https_git_acl_format: 'condensed',
            use_ci_gateway: false
          }
        )
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to eq(IO.read('spec/fixtures/frontend.template'))
        }

        expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
      end
    end

    context 'secrets in Chef vault' do
      populate_node_properties

      it_behaves_like 'configuring frontend haproxy'
    end
  end

  context 'with a valid GCE zone but no zone configured servers' do
    populate_node_properties
    normal_attributes['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'

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
              'web_k8s' => {},
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
              'web_k8s' => {},
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
          },
          https_git_acl_format: 'condensed',
          use_ci_gateway: false
        }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c' do
    populate_node_properties_zonal
    normal_attributes['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'

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
              'web_k8s' => {},
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
              'web_k8s' => {},
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
          },
          https_git_acl_format: 'condensed',
          use_ci_gateway: false
        }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c, but without a canary server in the same zone' do
    populate_node_properties_zonal

    # This switches the canary web node from us-east1-c to us-east1-d.
    # Because the LB is in us-east1-c this tests that web-cny-01 is
    # only marked as a backup.
    normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-c'].delete('canary_web')
    normal_attributes['gitlab-haproxy']['frontend']['backend']['servers']['us-east1-d']['canary_web']['web-cny-01.stg.gitlab.com'] = '127.0.0.1'
    normal_attributes['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'

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
              'web_k8s' => {},
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
              'web_k8s' => {},
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
          },
          https_git_acl_format: 'condensed',
          use_ci_gateway: false
        }
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('server web-cny-01.stg.gitlab.com 127.0.0.1:443 check check-ssl inter 3s fastinter 1s downinter 5s fall 3 ssl verify none backup')
      }
      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c and backup servers' do
    populate_node_properties_zonal_backup
    override_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy_report_only_enabled'] = false
    normal_attributes['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'

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
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1', 'git-cny-default-server' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
              'web_k8s' => {},
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
            'all' => {
              'api' => { 'api01.stg.gitlab.com' => '127.0.0.1', 'api02.stg.gitlab.com' => '127.0.0.1' },
              'canary_api' => { 'api-cny-01.stg.gitlab.com' => '127.0.0.1', 'api-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'canary_https_git' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1', 'git-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'canary_ssh' => { 'git-cny-01.stg.gitlab.com' => '127.0.0.1', 'git-cny-02.stg.gitlab.com' => '127.0.0.1', 'git-cny-default-server' => '127.0.0.1' },
              'canary_web' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1', 'web-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'canary_websockets' => { 'web-cny-01.stg.gitlab.com' => '127.0.0.1', 'web-cny-02.stg.gitlab.com' => '127.0.0.1' },
              'https_git' => { 'git01.stg.gitlab.com' => '127.0.0.1', 'git02.stg.gitlab.com' => '127.0.0.1' },
              'ssh' => { 'git01.stg.gitlab.com' => '127.0.0.1', 'git02.stg.gitlab.com' => '127.0.0.1' },
              'web' => { 'web01.stg.gitlab.com' => '127.0.0.1', 'web02.stg.gitlab.com' => '127.0.0.1' },
              'web_k8s' => {},
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1', 'web02.stg.gitlab.com' => '127.0.0.1' },
            },
          },
          https_git_acl_format: 'condensed',
          use_ci_gateway: false
        }
      )

      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend-with-backup-servers.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'when package_registry_enforced is enabled' do
    populate_node_properties
    override_attributes['gitlab-haproxy']['frontend']['web']['content_security_policy_report_only_enabled'] = false
    normal_attributes['gitlab-haproxy']['frontend']['api']['rate_limit_package_registry_rate_per_minute'] = '7000'
    normal_attributes['gitlab-haproxy']['frontend']['api_rate_limit']['enforced'] = true
    normal_attributes['gitlab-haproxy']['frontend']['api_rate_limit']['package_registry_enforced'] = true

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
              'web_k8s' => {},
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
              'web_k8s' => {},
              'websockets' => { 'web01.stg.gitlab.com' => '127.0.0.1' },
            },
          },
          https_git_acl_format: 'condensed',
          use_ci_gateway: false
        }
      )

      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/frontend-with-package-registry-enforced.template'))
      }

      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end

  context 'with zone configured servers with the lb in us-east1-c and no web servers' do
    populate_node_properties_zonal_missing_essential
    normal_attributes['gce']['instance']['zone'] = 'projects/65580314219/zones/us-east1-c'

    it 'creates the template and runs correct notifications' do
      expect { chef_run }.to raise_error(RuntimeError, 'Essential backend web has zero active servers configured: {"api"=>{"api01.stg.gitlab.com"=>"127.0.0.1"}, "https_git"=>{"git01.stg.gitlab.com"=>"127.0.0.1"}, "ssh"=>{"git01.stg.gitlab.com"=>"127.0.0.1"}, "web"=>{}, "web_k8s"=>{}, "websockets"=>{"web01.stg.gitlab.com"=>"127.0.0.1"}, "canary_web"=>{"web-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_websockets"=>{"web-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_api"=>{"api-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_ssh"=>{"git-cny-01.stg.gitlab.com"=>"127.0.0.1"}, "canary_https_git"=>{"git-cny-01.stg.gitlab.com"=>"127.0.0.1"}}, aborting!')
    end
  end

  context 'with tcp-check' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['frontend']['asset_proxy']['enable'] = true
    normal_attributes['gitlab-haproxy']['frontend']['asset_proxy']['host'] = 'gitlab-pre-assets.storage.googleapis.com'
    normal_attributes['gitlab-haproxy']['frontend']['web']['tcp_check_enable'] = true
    normal_attributes['gitlab-haproxy']['frontend']['api']['tcp_check_enable'] = true
    normal_attributes['gitlab-haproxy']['frontend']['https_git']['tcp_check_enable'] = true
    normal_attributes['gitlab-haproxy']['frontend']['websockets']['tcp_check_enable'] = true
    normal_attributes['gitlab-haproxy']['frontend']['ssh']['tcp_check_enable'] = true

    it 'enables http check via tcp for web' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('option tcp-check')
        expect(content).not_to include('tcp-check expect rstring HTTP/1\..\ 2..')
        expect(content).to include('server git01.stg.gitlab.com 127.0.0.1:22 weight 100 check check-ssl port 443 verify none inter 3s fastinter 1s downinter 5s fall 3')
        expect(content.scan(tcp_check).size).to eq(0)
      }
    end

    context 'when only tcp checks' do
      normal_attributes['gitlab-haproxy']['frontend']['ssh']['check_opts'] = ''
      it 'ssh has tcp only check' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to include('option tcp-check')
          expect(content).to include('server git01.stg.gitlab.com 127.0.0.1:22 weight 100 check  inter 3s fastinter 1s downinter 5s fall 3')
          expect(content).not_to include('server git01.stg.gitlab.com 127.0.0.1:22 weight 100 check check-ssl port 443 verify none inter 3s fastinter 1s downinter 5s fall 3')
          expect(content.scan(tcp_check).size).to eq(0)
        }
      end
    end
  end

  context 'with systemd override' do
    populate_node_properties

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
    populate_node_properties
    normal_attributes['gitlab-haproxy']['systemd_service_overrides']['enable'] = false

    it 'does not creates the systemd overrides' do
      expect(chef_run).not_to render_file('/etc/systemd/system/haproxy.service.d/override.conf')
    end
  end

  context 'with extra HTTPS bind port' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['frontend']['https']['extra_bind_port'] = 11443

    it 'includes an extra bind directive with the supplied port' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('bind 0.0.0.0:11443 ssl crt /etc/haproxy/ssl/gitlab.pem')
      }
    end
  end

  context 'with api rate limit bypass enabled for QA useragent' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['frontend']['https']['api_ratelimit_bypass_for_useragent']['enable'] = true
    normal_attributes['gitlab-haproxy']['frontend']['https']['api_ratelimit_bypass_for_useragent']['useragent'] = 'custom_qa_agent'

    it 'includes acl and use_backend rules for header-based bypass' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        frontend_https = parse_config(content)['frontend https']
        expect(frontend_https).to include('acl is_qa_useragent hdr(User-Agent) custom_qa_agent')
        expect(frontend_https).to include('use_backend api if is_gitlab_com_api is_qa_useragent')
      }
    end
  end

  context 'with bypass rate limit header enabled' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['frontend']['https']['enable_ratelimit_bypass_header'] = true
    normal_attributes['gitlab-haproxy']['frontend']['https']['enable_jwt_auth_ratelimit_bypass'] = false
    normal_attributes['gitlab-haproxy']['frontend']['https']['enable_package_registry_ratelimit_bypass'] = false

    def set_bypass(acl)
      "http-request set-header X-GitLab-RateLimit-Bypass 1 if #{acl}"
    end

    it 'includes bypass header setting code' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        frontend_https = parse_config(content)['frontend https']

        expect(frontend_https).to include('http-request set-header X-GitLab-RateLimit-Bypass 0')

        %w(whitelist_api api_rate_limit_whitelist is_https_git).each do |acl|
          expect(frontend_https).to include(set_bypass(acl))
        end

        %w(is_gitlab_com_jwt_auth is_gitlab_com_package_registry is_gitlab_com_go_get).each do |acl|
          expect(frontend_https).not_to include(set_bypass(acl))
        end
      }
    end

    it 'orders the bypass for whitelist_internal correctly' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        frontend_https = parse_config(content)['frontend https']
        set_header_index = frontend_https.index('http-request set-header X-GitLab-RateLimit-Bypass 1 if whitelist_internal')
        request_allow_index = frontend_https.index('http-request allow if whitelist_internal')

        expect(set_header_index).to be < request_allow_index
      }
    end

    context 'and jwt_auth ratelimit bypass enabled' do
      normal_attributes['gitlab-haproxy']['frontend']['https']['enable_jwt_auth_ratelimit_bypass'] = true

      it 'sets a header for is_gitlab_com_jwt_auth' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(parse_config(content)['frontend https']).to include('http-request set-header X-GitLab-RateLimit-Bypass 1 if is_gitlab_com_jwt_auth')
        }
      end
    end

    context 'and package registry ratelimit bypass enabled' do
      normal_attributes['gitlab-haproxy']['frontend']['https']['enable_package_registry_ratelimit_bypass'] = true

      it 'sets sets a header for is_gitlab_com_package_registry' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(parse_config(content)['frontend https']).to include('http-request set-header X-GitLab-RateLimit-Bypass 1 if is_gitlab_com_package_registry')
        }
      end
    end

    context 'and go get ratelimit bypass enabled' do
      normal_attributes['gitlab-haproxy']['frontend']['https']['enable_go_get_ratelimit_bypass'] = true

      it 'sets sets a header for is_gitlab_com_package_registry' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(parse_config(content)['frontend https']).to include('http-request set-header X-GitLab-RateLimit-Bypass 1 if is_gitlab_com_go_get')
        }
      end
    end
  end

  context 'with package registry rate limit enabled' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['frontend']['api_rate_limit']['package_registry_enforced'] = true

    it 'includes package registry configuration' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        frontend = parse_config(content)['frontend api_rate_limit']

        expect(frontend).to include('acl is_gitlab_com_package_registry path_reg ^/api/v[0-9]/packages/')
        expect(frontend).to include('acl is_package_registry_rate_abuse src_http_req_rate gt 7000')
        expect(frontend).to include(
          'http-response set-header RateLimit-Limit 7000 if is_gitlab_com_package_registry !has_ratelimit_headers'
        )
        expect(
          frontend.grep(
            /http-response set-header RateLimit-Remaining.*if is_gitlab_com_package_registry !has_ratelimit_headers/
          )
        ).to_not be_empty
      }
    end
  end

  context 'with ci-gateway enabled' do
    populate_node_properties
    normal_attributes['gitlab-haproxy']['ci-gateway']['enabled'] = true
    normal_attributes['gitlab-haproxy']['ci-gateway']['allowlisted_runner_managers'] = ['10.1.5.0/24']

    it 'includes the https_git_ci_gateway frontend' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include(File.read('spec/fixtures/ci-gateway-frontend.template'))
      }
    end

    it 'adds ci-gateway certificate to the https frontend' do
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to include('bind 0.0.0.0:443 ssl crt /etc/haproxy/ssl/gitlab.pem no-sslv3 ssl crt /etc/haproxy/ssl/ci-gateway.pem')
      }
    end

    context 'when https_git_acl_format is verbose' do
      normal_attributes['gitlab-haproxy']['frontend']['https_git']['use_verbose_acls'] = true

      it 'includes the verbose https_git ACLs' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to include(File.read('spec/fixtures/https_git_acl_verbose.template'))
        }
      end
    end

    context 'when redirect_all_traffic_externally is set to true' do
      normal_attributes['gitlab-haproxy']['ci-gateway']['redirect_all_traffic_externally'] = true

      it 'uses ci_gateway_catch_all backend exclusively' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).not_to include('use_backend api if is_runner_manager')
          expect(content).not_to include('use_backend https_git if is_https_git is_git_method')
          expect(content).to include('default_backend ci_gateway_catch_all')
        }
      end
    end

    context 'when redirect_using_lua is set to true' do
      normal_attributes['gitlab-haproxy']['ci-gateway']['redirect_using_lua'] = true

      it 'creates a Lua script called ci-gateway-redirect.lua' do
        content = <<~LUA
          -- For rationale, please read https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/14874#note_863790316
          core.register_service("ci-gateway-redirect-307", "http", function(applet)
             applet:set_status(307)
             applet:add_header("location", "https://gitlab.com" .. applet.path)
             applet:start_response()
             applet:send("")
             applet:receive(1)
          end)
        LUA

        expect(chef_run).to render_file('/etc/haproxy/scripts/ci-gateway-redirect.lua').with_content(content)
      end

      it 'uses Lua to return the redirects' do
        expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
          expect(content).to include('lua-load /etc/haproxy/scripts/ci-gateway-redirect.lua')
          expect(content).to include('http-request use-service lua.ci-gateway-redirect-307')
          expect(content).not_to include('http-request redirect code 307 location https://gitlab.com%[capture.req.uri]')
        }
      end
    end
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
