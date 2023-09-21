# Cloudera Ansible Execution Environments

`cldr-runner` is set of Ansible [Execution Environments](https://ansible.readthedocs.io/projects/builder/en/stable/#execution-environments) for running Cloudera playbooks, examples, and general automation for both CDP Public Cloud, Private Cloud, and Data Services. These images are appropriate for use with `ansible-navigator`[^1] and AWS/AAP.

`cldr-runner` consists of several variations:

| Tag | Description |
|-----|-------------|
| base | Core Ansible, collections, and dependencies including Terraform |
| aws | `base` plus AWS-specific collections and dependencies, including the `aws` CLI |
| azure | `base` plus Azure-specific collections and dependencies, including the `az` CLI |
| gcp | `base` plus GCP-specific collections and dependencies, including the `gcloud` CLI |
| full | All of the above, plus additional CLI tools for in-container usage, e.g. `git`, `vim`, `nano`, `tree`, `kubectl` |

## Building

If you need to construct a local image, first set up a Python virtual environment with the latest `ansible-core` and `ansible-builder`:

```bash
python -m venv ~/location/of/venv; source ~/location/of/venv/bin/activate; pip install ansible-builder
```

HINT: If you have already set up `ansible-navigator`, then you have `ansible-builder`!

Then change into the directory of the `cldr-runner` variation you need to build and run:

```bash
ansible-builder build --prune-images --squash all --build-arg BUILD_VER=<your particular version> --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") --tag <your particular tag> 
```

You may want to update the variation's `execution-environment.yml` configuration file to use a different base image, say a local image, or build the `base` image before constructing CSP or `full` image. You can make this change in the following section of the configuration file:

```yaml
images:
  base_image:
    name: <your particular base image>
```

## Usage

Typically, a `cldr-runner` image is used with `ansible-navigator` as defined within an `ansible-navigator.yml` configuration file:

```yaml
ansible-navigator:
  execution-environment:
    container-engine: docker
    enabled: True
    image: <your cldr-runner image tag>
```

You can specify the image via the CLI[^1], e.g. `--eei` or `--execution-environment-image`.

## Local Development

The `cldr-runner` project can also be used to bootstrap a local development environment on the native host environment (as opposed to an Execution image).  This option is more involved, but can avoid issues with Docker, such as mount latencies, and improve collection development. 

The `local_development.yml` playbook sets up a `cldr-runner`-like workspace for OSX and Ubuntu.  The playbook will clone the Cloudera collections and `cdpy` for local work, install the external Ansible dependencies, update the Python `venv`, and create a convenient setup script for future work.

NOTE: The cloned Cloudera collections and cdpy project use the `main` branches by default. Manipulating the branches, etc. is outside the scope of the `local_development.yml` playbook.

NOTE: If you are using an M1 or M2 Macbook, to ensure compatibility and prevent library incompatibilities between architectures, enable the Rosetta within your terminal. Go to `Finder > Applications` and then for your terminal, go to `Terminal > <right-click on your Terminal> > Get Info > Enable "Open using Rosetta"`.

Development in this manner starts with sourcing the setup script, activating the virtual environment, and then switching to and running `cldr-runner`-based applications, such as `ansible-navigator`-based `cloudera-deploy` definitions, within their own projects while using the development environment's collections and tools. 

You can change the execution environment by updating the Git-backed projects within the `ansible_collections` directory of the development environment or wholesale by changing the virtual environment and/or pointing to other development environments via the Ansible collection and role paths (see the setup scripts for details).

*Follow these steps to set up a local environment:*

Create a new virtual environment (using your favorite `venv` app):

```bash
$ mkvirtualenv <your development directory>
```

Set up the bootstrap requirements:

```bash
$ export ANSIBLE_COLLECTIONS_PATH=<your target development directory>
$ pip install ansible-base==2.10.16
$ ansible-galaxy collection install community.general
```

Make sure you are able to connect to public GitHub via SSH and then construct the development environment:

```bash
$ ansible-playbook local_development.yml
```

NOTE: For Ubuntu deployments, you will need to add the `--ask-become-pass` flag.

Source the `setup-ansible-env.sh` file to use this development environment.
```bash
$ source <your development directory>/setup-ansible-env.sh
```

## Contributing

Please create a feature branch from a current `devel` branch, and submit a PR against the same while referencing an issue.

Note that we require signed commits inline with [Developer Certificate of Origin](https://developercertificate.org/) best-practices for open source collaboration.

A signed commit is a simple one-liner at the end of your commit message that states that you wrote the patch or otherwise have the right to pass the change into open source.  Signing your commits means you agree to:

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
660 York Street, Suite 102,
San Francisco, CA 94110 USA

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

(See [developercertificate.org](https://developercertificate.org/))

To agree, make sure to add line at the end of every git commit message, like this:

```
Signed-off-by: John Doe <jdoe@example.com>
```

TIP! Add the sign-off automatically when creating the commit via the `-s` flag, e.g. `git commit -s`.

[^1] https://ansible.readthedocs.io/projects/navigator/

## License and Copyright

Copyright 2023, Cloudera, Inc.

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```