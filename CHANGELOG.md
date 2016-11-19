# 0.1.20

- increase logging length limit from 1024 (default) to 4096

# 0.1.19

- Change error in tcp logging flags

# 0.1.18

- Change default logging to include bytes_written

# 0.1.17

- Change expiration time for counter from 5m to 1m to better model usage patterns

# 0.1.16

- Move redirect for doc to pages template

# 0.1.15

- Added redirect for doc to docs.gitlab.com

# 0.1.14

- Drop chef search and use attributes for nodes

# 0.1.13

- move slow-hand.rb to correctly be an erb template

# 0.1.12

- Impliment lua function for slow-down of bad traffic

# 0.1.10

- Provide better throttling for connections

# 0.1.9

- Add landing support for get.gitlab.com

# 0.1.8

- Add landing support for feedback.gitlab.com

# 0.1.7

- Refactor cookbook into gitlab-haproxy

# 0.1.6

- Add landing support for ce.gitlab.com and ee.gitlab.com

# 0.1.5

- fixed and error with redirecting jobs.gitlab.com

# 0.1.4

- Add jobs.gitlab.com landing redirection

# 0.1.3

- Set pass to 0 for nfs mounts

# 0.1.2

- Add the git-data-alt mountpoint

# 0.1.0

Initial release of gitlab-nfs-cluster
