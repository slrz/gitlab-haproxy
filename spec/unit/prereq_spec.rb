require 'spec_helper'

describe 'gitlab-haproxy::prerequisites' do
  context 'prerequisites execution' do
    before do
      mock_secrets_path = 'test/integration/data_bags/secrets/certs.json'
      secrets = JSON.parse(File.read(mock_secrets_path))

      expect_any_instance_of(Chef::Recipe).to receive(:get_secrets)
        .with('hashicorp_vault', 'env/gstg/cookbook/gitlab-haproxy/frontend-loadbalancer').and_return(secrets)
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
