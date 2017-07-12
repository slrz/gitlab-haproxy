require "spec_helper"

describe "gitlab-haproxy::default" do
  context "default execution" do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new { |node|
      }.converge(described_recipe)
    end

    it 'converges successfully' do
      expect{ chef_run }.to_not raise_error
    end

    it "Installs packages" do
      expect(chef_run).to install_package("haproxy")
      expect(chef_run).to install_package("logrotate")
    end

    it "creates folders" do
      expect(chef_run).to create_directory('/etc/haproxy/ssl').with(
        mode: '0700',
        recursive: true
      )
      expect(chef_run).to create_directory('/etc/haproxy/errors').with(
        mode: '0700',
        recursive: true
      )
    end

    it "creates lots of cookbook files" do
      expect(chef_run).to create_cookbook_file("/etc/haproxy/errors/400.http").with(
        source: "haproxy-errors-400.http"
      )
      expect(chef_run).to create_cookbook_file("/etc/haproxy/errors/429.http").with(
        source: "haproxy-errors-429.http"
      )
      expect(chef_run).to create_cookbook_file("/etc/haproxy/errors/500.http").with(
        source: "haproxy-errors-500.http"
      )
      expect(chef_run).to create_cookbook_file("/etc/haproxy/errors/bad_ref.http").with(
        source: "haproxy-errors-bad-ref.http"
      )
      expect(chef_run).to create_cookbook_file("/etc/cron.hourly/logrotate").with(
        source: "logrotate-cron",
        owner: "root",
        group: "root",
        mode: "0755",
      )
      expect(chef_run).to create_cookbook_file("/etc/logrotate.d/haproxy").with(
        source: "logrotate-haproxy",
        owner: "root",
        group: "root",
        mode: "0644",
      )
    end
  end
end
