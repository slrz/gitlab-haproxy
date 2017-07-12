require "spec_helper"
require 'chef-vault/test_fixtures'

describe "gitlab-haproxy::altssh" do
  include ChefVault::TestFixtures.rspec_shared_context

  context "backend execution" do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new { |node|
        node.normal['gitlab-haproxy']['chef_vault'] = 'secrets'
        node.normal['gitlab-haproxy']['chef_vault_item'] = 'certs'
        node.normal['gitlab-haproxy']['altssh']['servers']['ssh01.stg.gitlab.com'] = '127.0.0.1'
      }.converge(described_recipe)
    end

    it 'converges successfully' do
      expect{ chef_run }.to_not raise_error
    end

    it "Includes default recipe" do
      expect(chef_run).to include_recipe('gitlab-haproxy::default')
    end

    it "creates the template and runs correct notifications" do
      expect(chef_run).to create_template('/etc/haproxy/haproxy.cfg').with(
        source: 'haproxy-altssh.cfg.erb',
        mode: '0600',
        variables: {:admin_password=>"this-is-a-test-password"}
      )
      expect(chef_run).to render_file('/etc/haproxy/haproxy.cfg').with_content { |content|
        expect(content).to eq(IO.read('spec/fixtures/altssh.template'))
      }
      expect(chef_run.template('/etc/haproxy/haproxy.cfg')).to notify('execute[test-haproxy-config]').to(:run).delayed
    end
  end
end
