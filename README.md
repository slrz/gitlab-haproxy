[![build status](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/badges/master/pipeline.svg)](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/pipelines)

# gitlab-haproxy

This is `gitlab-haproxy` cookbook to base your cookbook on.

## Run Order

Every flavor of HAProxy nodes (`main` - former `frontend`, `registry` and `pages`)
has their own starting point recipe of the same name, that does some initial configuration of the cookbook.

After installing the `prerequisites` (which includes all the `internal_*` recipes),
the flavor might do some specific additional configuration before installing and configuring HAProxy via the `install` recipe.

## Configuring Flavors

Every flavor now shares the same base configuration.
Differences can be made via node attributes either set in the cookbook for general configuration (preferred if possible)
or on a role level (which should be moved to the cookbook if applicable).

Selecting options to set for the `global` and `defaults` sections,
as well as each frontend name for each flavor works this way:

There is a general default value set.

```ruby
default['gitlab-haproxy']['config']['default']['global']['no-memory-trimming'] = ''
```

This value can be overridden by flavor (in this example `registry`) in this way:

```ruby
default['gitlab-haproxy']['config']['registry']['global']['no-memory-trimming'] = nil
```

It follows the general schema of
```ruby
default['gitlab-haproxy']['config'][<flavor>][<section>][<setting>] = <value>
```

Value can be either a string, number, or `nil`.

  - A string will set the value of the setting in the configuration file to the selected value.
    If a setting does not take a value (such as `no-memory-trimming`) an empty string can be provided.
    In general this string will be entered into the configuration verbatim.
  - `nil` will remove the value from the flavor, if it was previously set.

NOTE: Options (such as `option redispatch`) should be in the settings field as a string with space.
`redispatch` is not a value to the setting `option`
(e.g. `default['gitlab-haproxy']['config']['defaults']['defaults']['option redispatch'] = 1` is valid).

Timeouts are statically set in the `defaults` section by design.
If they should be adjusted, it MUST be done in the backend configuration.
Generally they should not be changed, unless there is a very good reason,
and you're sure of what changing the timeout in question does.

## Configuring Backends for Flavors

Every backend itself is a self-contianed template in `templates/default/backend/<backend_name>.erb`.  
This template will be enabled when it is contained in the `default['gitlab-haproxy']['enabled_backends'][<flavor>]` node attribute array.

Each template will receive the following variables:

| Variable            | Example | Description                                     |
|:--------------------|---------|-------------------------------------------------|
| `@name`             | `api`   | The backend name to which this is the template. | 

Each template should only include the backend definition template and provide the configuration for the backend, unless otherwise necessary.

```erb
<%= render 'boilerplate/backend_definition.erb', :variables => {
  name: # The name of the frontend, as included in the file name.
  description: # A description of what the backend's role is. Does it mix in other pools?, etc.
  mode: # 'http' or 'tcp'
  health_check: # optional. The health check configuration. Usually from node attributes.
  override_host: # optional. If set, the `Host` header will be overridden to this string for backend servers.
  source_nodes: # recommended. An array containing name of configured node pools (e.g. `['api', 'canary_api']`) These will get a higher weight.
  mixin_nodes: # optional. An array containing name of configured node pools - usually canary (e.g. `['canary_api']`) These will get a lower weight.
  fallback_values_from_pool: # opional. Any values not specifically configured in a node pool used above, will be taken from this pool instead. Used for legacy compatibility.
  port_override: # optional. Override the port used to connect to backend servers (for example if the configured port for the node pool is incorrect)
  check_port_override: # optional. Override the port used in the health check (for example if the configured port health check is incorrect)
  stick_with_cookie: # optional. If `true`, backend servers will be stuck to a client via a cookie.
} -%>
```

Should `source_nodes` not be defined, there will be no backend servers rendered.
This is useful if a backend is statically configured to point to object storage,
or just performs operations inside of HAProxy (see `asset_proxy` as an example).

#### Backend Settings

The backends can have settings set similar to the `defaults` and `global` sections.
This will be rendered as part of the backend definition.
You SHOULD NOT add settings in the template! If in doubt, do it in attributes!

```ruby
default['gitlab-haproxy']['config']['<flavor>']['backend']['<backend name>']['<config key>'] = '<config value>'
```

For example

```ruby
default['gitlab-haproxy']['config']['main']['backend']['https_git']['timeout server'] = '1h'
```

NOTE: Settings set on backends are NOT inheriting anything.
These are included verbatim in the backend and should be used if value from the `defaults` section should be changed on a backend basis. Setting a value to `nil` here will NOT undo the effects of the `defaults` counterpart.
You need to set the opposing option according to the HAProxy documentation.

## Configuring Frontends for Flavors

Every frontend itself is a self-contianed template in `templates/default/frontends/<frontend_name>.erb`.  
This template will be enabled when it is contained in the `default['gitlab-haproxy']['enabled_frontends'][<flavor>]` node attribute array.

Each template will receive the following variables:

| Variable            | Example                                    | Description                                                                                                                             |
|:--------------------|--------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `@name`             | `https`                                    | The frontend name to which this is the template.                                                                                        | 

Each template should start with the frontend definition template and provide the configuration for the frontend.

```erb
<%= render 'boilerplate/frontend_definition.erb', :variables => {
  :name => # The name of the frontend, as included in the file name.
  :bind_addresses => # The list of addresses to bind on them
  :bind_port=> # The port to bind on
  :bind_extra_options => # optional. a string with additional options to specify on the bind command
  :https_extra_bind_port => # optional. should `enforce_cf_origin_pull` be true, specifying this port will create another identical bind statemend without mTLS
  :enforce_cf_origin_pull => # optional. If true, mTLS connections from Cloudflare are required
  :listen_certificates => # Provide an array of the certificates you with to bind to. Empty array disables TLS for the frontend. Any certificates not present on the machine will fail the rendering. This is by design, as HAProxy would crash with that configuration.
  :skip_headers => # optional. if true, will disable automatic headers. Implies `minimal == true`.
  :minimal => # if true, the `canary_opt_in` and `canary_opt_out` ACLs are not generated.
  :skip_availability_acls => # if true, the backend_available_<backend_name> ACLs are not generated for every enabled backend.
  :mode => # 'http' or 'tcp'. This impacts automatic headers, and the log format. (For TCP connection GitLab uses a different log format from the default HTTP logs)
  :expect_proxy => # 'HTTP', 'TCP' or any other value. See expect proxy definition below.
} -%>
```

`expect_proxy`: If this is either 'HTTP' or 'TCP' (uppercase), it will check if a connection comes from the Cloudflare IP range (in case of HTTP also check a CF specific header), and then inject the original client IP as the source for the request/connection.

  - Should a connection not come from CF IP ranges, this will not do anything,
    so it is safe to include in any backend that may or may nor receive Cloudflare traffic.
  - If set to 'TCP', a connection from CF IP ranges is required to be encapsulated in PROXYv2
    If set to 'HTTP' it will only apply the client IP if it was provided by Cloudflare.
    This is guaranteed for client access.
    Cloudflare Worker requests might be initiated separately and thus not always carry a client IP association.
  - This is not bound to the `mode` parameter, as there might be valid reasons to have a `http` `mode`,
    but request raw PROXYv2 connections as incoming.

Each frontend template has access to template helpers, which are [#template-helpers](defined further below).

#### Available ACLs:

The frontend definition will render the following ACLs for use in the template (unless disabled via parameters)

  - `canary_opt_in`: This will evaluate to `true` if the request has an explicit opt-in from [next.gitlab.com].
    If the user has not explicitly opted in, this is `false`.
  - `canary_opt_out`: This will evaluate to `true` if the request has an explicit opt-out from [next.gitlab.com].
     If the user has explicitly opted in, this is `false`.
     If the user did not decide either way, this is also `false`.
  - `backend_available_<backend_name>`: For each enabled backend of the flavor this ACL will be generated.
    If the amount of available backend servers is `> 0`, this will evaluate to `true`.
    Thus, when this is `false` no backend server is available on the specific backend.

#### Automatic Headers (`mode == http` only, unless `skip_headers == true`)

  - `Client-Ip` is deleted if provided.
  - `X-Forwarded-For` is set to the source IP (after `expect_proxy` treatment, if applicable)
  - `GitLab-Real-IP` is set to the source IP (after `expect_proxy` treatment, if applicable)
  - `X-Forwarded-Proto` is set to `https` (unless no `listen_certificates` were provided, and thus TLS is disabled. Then `http`)
  - `X-SSL` is set to `true` (unless no `listen_certificates` were provided, and thus TLS is disabled. Then `false`)
  - `X-GitLab-RateLimit-Bypass` and all other normalized version of the header is dropped (unless `minimal == true`)
  - `GitLab-LB` is set to the HAProxy node's hostname serving the request
  - `GitLab-SV` is set to the backend server name serving the request

#### Allowlists

If you wish to enable the GitLab standard IP and path blocks,
include the following snippet in the template, right before backend routing:

For an HTTP frontend:

```erb
<%= render 'boilerplate/http_front-end-security.erb' %>
```

For an TCP frontend:

```erb
<%= render 'boilerplate/tcp_front-end-security.erb' %>
```

For an HTTP frontend the standards internal allowlist is automatically exempt from any blocklists.
Custom rules should be sandwiched between the frontend definition and the inclusion of the above snippet.

#### Frontend Settings

The frontends can have settings set similar to the `defaults` and `global` sections.
This will be rendered as part of the frontend definition.
You SHOULD NOT add settings in the template! If in doubt, do it in attributes!

```ruby
default['gitlab-haproxy']['config']['<flavor>']['frontend']['<frontend name>']['<config key>'] = '<config value>'
```

For example

```ruby
default['gitlab-haproxy']['config']['main']['frontend']['https']['timeout client'] = '1337s'
```

NOTE: Settings set on frontends are NOT inheriting anything.
These are included verbatim in the frontend and should be used if value from the `defaults` section should be changed on a frontend basis. Setting a value to `nil` here will NOT undo the effects of the `defaults` counterpart.
You need to set the opposing option according to the HAProxy documentation.

## Template-Helpers

Each template (backend and frontend) has access to these template helpers.
They can be accessed directly in any erb expression.

  - `cookbook_version`: Return the current version of the cookbook as defined in `metadata.rb`
  - `get_attribute(*query)`: A `.dig()`-like function to retrieve a node attribute.
    For example `get_attribute('gitlab-haproxy', 'flavor')` would return the same as `node['gitlab-haproxy']['flavor']`.
  - `peers` returns an array of peer nodes for the current HA cluster flavor.
  - `flavor` returns the current flavor.
  - `enabled_backends` returns an array of the names of currently enabled backends.
  - `enabled_frontends` returns an array of the names of currently enabled frontends.
  - `check_frontends` returns an array of the names of currently enabled `check_*` frontends.
  - `chef_attribute_settings(*query)`: `.dig()`-like access to merged settings for
    the current flavor to embed into the HAProxy configuration sections, backends, and frontends.
  - `admin_password` returns the password to set for the stats endpoint.
  - `filter_certificates(wanted)`: Checks the passed array of wanted filenames against the available certificates on the node.
    Raises an error if one cannot be found.
  - `build_check_opts(backend_name)` returns the `check` options for a given `backend_name`.
  - `build_ssl_opts(backend_name)` returns the `ssl` options for a given `backend_name`.
    If no ssl options are found, returns `no-ssl` for compatibility.
  - `backend_servers_by_pool(pool_name, fallback_pool_name)` returns an array of backend servers to use from a given `pool_name`.
    Any missing values are substituted from the `fallback_pool_name`'s configuration values.

## Testing

The Makefile, which holds all the logic, is designed to be the same among all cookbooks.
Just set the comment at the top to include the cookbook name and you are all set to use the below testing instructions.

### Testing Locally

You can run `kitchen` tests directly without using provided `Makefile`,
although you can follow instructions to benefit from it.

  1. Install GNU Make (`apt-get install make`). Under OS X you can achieve the
     same by `brew install make`. After this, you can see available targets of
     the Makefile just by running `make` in cookbook directory.

  1. Install `libsodium`: `brew install libsodium`

  1. Cheat-sheet overview of current targets:
     - `make gems`: install latest version of required gems into directory, specified by environmental variable `BUNDLE_PATH`.
       By default it is set to the same directory as on CI, `.bundle`, in the same directory as Makefile is located.
     - `make check`: find all `*.rb` files in the current directory, excluding ones in `BUNDLE_PATH`, and check them with rubocop.
     - `make kitchen`: calculate the number of suites in `.kitchen.do.yml`, and run all integration tests,
       using the calculated number as a `concurrency` parameter. In order to this locally by default,
       copy the example kitchen config to your local one: `cp .kitchen.do.yml .kitchen.local.yml`,
       or export environmental variable: `export KITCHEN_YAML=".kitchen.do.yml"`
       _Note_ that `.kitchen.yml` is left as a default Vagrant setup and is not used by Makefile.

### On CI

Alternatively, you can just push to your branch and let CI handle the testing. `make kitchen` target will:

  - detect the CI environment
  - generate ephemeral SSH ed25519 keypair
  - run the kitchen test
  - clean up the ephemeral key from GCP after pipeline is done

See `.gitlab-ci.yml` for details, but the overall goal is to have only `make kitchen` in it,
and cache `$BUNDLE_PATH` for speed.

Current CI configuration basically enforces all of the following to succeed, in defined order, for a pipeline to pass:

  - Rubocop should be happy with every ruby file and exit with code zero, without any warnings or errors.
  - Integration tests must all pass.

## Versioning

This repo **doesn't** use conventional commits for publishing new versions. Instead, you need to bump the version in `metadata.rb` manually, following [semver](https://semver.org/).