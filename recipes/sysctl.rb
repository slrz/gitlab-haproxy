# Tweak sysctls

# Some tuning based on a nice blog article[0].
#
# [0]: https://medium.com/@pawilon/tuning-your-linux-kernel-and-haproxy-instance-for-high-loads-1a2105ea553e

# Allow more half-open connections to avoid SYN floods.
sysctl 'net.ipv4.tcp_max_syn_backlog' do
  value '10000'
end

# Increase maximum connections to allow connection bursts.
sysctl 'net.core.somaxconn' do
  value '65535'
end

# Increase the local port range to expand 5-tuple capcity.
sysctl 'net.ipv4.ip_local_port_range' do
  value '1024 65535'
end
