module Gitlab
  def self.private_ips_for_node(n)
    non_local_interface = n['network']['interfaces'].find { |k, _| k != 'lo' }
    return [] if non_local_interface.nil?

    non_local_interface.last['addresses'].map do |addr, details|
      addr if details['family'] == 'inet'
    end.compact
  end
end
