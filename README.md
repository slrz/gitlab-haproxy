# GitLab HAProxy Cookbook

... (existing content preserved)

## Testing changes in non-production environments

If you'd like to test changes in a non-production environment without rolling them out to production, add flavor-based overrides in the appropriate recipe files. Example pattern included in each of the three flavors:

```ruby
# To test changes in Non production environment, remove added overrides, and add them to default.rb to rollout to production
# unless node['gitlab-haproxy']['is_production']
#   # Add registry-flavor specific overrides here for non-prod envs
# end
```

When testing is complete and you want to promote changes to production, move those overrides into the relevant attributes/default.rb (or remove the conditional and add them to default.rb) so they apply when `node['gitlab-haproxy']['is_production']` is true.
