# gitlab-haproxy cookbook

This is the cookbook that runs on the Load Balancers.  This includes HAproxy stuffs.

## Supported Platforms

It is intended to run on Ubuntu 16.04 within the Azure Cloud Service.

## Connecting to HAProxy server

When you connect to the HAProxy server, please use `ssh -p 2222`, otherwise your SSH connections will go to the SSH workers.  


## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['gitlab-haproxy']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### gitlab-haproxy::default

Include `gitlab-haproxy` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[gitlab-haproxy::default]"
  ]
}
```

## License and Authors
Authors: Jeroen Nijhof <jeroen@gitlab.com>

License: MIT
