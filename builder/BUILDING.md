# Building a Local cldr-runner Image

`cldr-runner` is an [`ansible-runner`](https://github.com/ansible/ansible-runner) image constructed using the [`ansible-builder`](https://github.com/ansible/ansible-builder) application.

`cldr-runner` has five core profiles:

* `base` - the Cloudera collections and their dependencies.
* `aws` - builds on `base` and adds the AWS dependencies.
* `azure` - builds on `base` and adds the Azure dependencies.
* `gcp` - builds on `base` and adds the Google Cloud dependencies.
* `full` - includes all of the above plus additional applications for using the image for development and general execution, e.g. `nano`.

Each profile is designed to draw from either the `main` or `devel` branches of the various Cloudera collections; the `ansible-builder` _context_ is a constructed with either `builder/main` or `builder/devel`. It then runs with the appropriate _Execution Environment_ configuration file, e.g. `builder/ee-base.yml` within this _context_.

To coordinate this process at the CLI, you can run `builder/build.sh` with the appropriate parameters, and the script will copy the proper resources and return next step instructions.

```bash
$> builder/build.sh main base

Context created! Please run the following to build the Execution Environment image:

  ansible-builder build -c builder/contexts/base-main -f builder/contexts/base-main/execution-environment.yml -t cldr-runner:base-main --build-arg BUILD_VER="base-main" --prune-images

Add the '-v 3' flag if you wish to see verbose logging.
```

Which when run, for example:

```bash
$> ansible-builder build -c builder/contexts/base-main -f builder/contexts/base-main/execution-environment.yml -t cldr-runner:base-main --build-arg BUILD_VER="base-main" --prune-images
```

Resulting in the following:

```bash
Running command:
  podman build -f builder/contexts/base-main/Containerfile -t cldr-runner:base-main --build-arg=BUILD_VER=base-main builder/contexts/base-main
Running command:
  podman image prune --force
Complete! The build context can be found at: /Users/wmudge/tmp/cldr-runner/builder/contexts/base-main
```

Based on the `-t` (tag) parameter specified above, the resulting image is set in the local repository as `localhost/cldr-runner:base-main`.