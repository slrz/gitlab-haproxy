[![build status](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/badges/master/pipeline.svg)](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/pipelines)

# gitlab-haproxy

This is gitlab-haproxy cookbook to base your cookbook on.

## Using

Describe how your cookbook should be used.

## Testing

The Makefile, which holds all the logic, is designed to be the same among all
cookbooks. Just set the comment at the top to include the cookbook name and
you are all set to use the below testing instructions.

### Testing locally

You can run `rspec` or `kitchen` tests directly without using provided
`Makefile`, although you can follow instructions to benefit from it.

1. Install GNU Make (`apt-get install make`). Under OS X you can achieve the
   same by `brew install make`. After this, you can see available targets of
   the Makefile just by running `make` in cookbook directory.

1. Cheat-sheet overview of current targets:

   - `make gems`: install latest version of required gems into directory,
     specified by environmental variable `BUNDLE_PATH`. By default it is set to
     the same directory as on CI, `.bundle`, in the same directory as Makefile
     is located.

   - `make check`: find all `*.rb` files in the current directory, excluding ones
     in `BUNDLE_PATH`, and check them with rubocop.

   - `make rspec`: the above, plus run all the rspec tests. You can use
     `bundle exec rspec -f d` to skip the lint step, but it is required on CI
     anyways, so rather please fix it early ;)

   - `make kitchen`: calculate the number of suites in `.kitchen.do.yml`, and
     run all integration tests, using the calculated number as a `concurrency`
     parameter. In order to this locally by default, copy the example kitchen
     config to your local one: `cp .kitchen.do.yml .kitchen.local.yml`, or
     export environmental variable: `export KITCHEN_YAML=".kitchen.do.yml"`

     _Note_ that `.kitchen.yml` is left as a default Vagrant setup and is not
     used by Makefile.

### On CI

Alternatively, you can just push to your branch and let CI handle the testing.
`make kitchen` target will:

- detect the CI environment
- generate ephemeral SSH ed25519 keypair
- run the kitchen test
- clean up the ephemeral key from DigitalOcean after pipeline is done

See `.gitlab-ci.yml` for details, but the overall goal is to have only
`make rspec` and `make kitchen` in it, and cache `$BUNDLE_PATH` for speed.

Since `make check` is a prerequisite for `make rspec`, current CI configuration
basically enforces all of the following to succeed, in defined order, for a
pipeline to pass:

- Rubocop should be happy with every ruby file and exit with dcode zero,
  without any warnings or errors.
- Rspec tests must all pass.
- Integration tests must all pass.
