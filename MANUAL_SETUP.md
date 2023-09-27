# Local Development Environment (Manual Setup)

If you do not wish to run the `local_development.yml` playbook to set up your local development environment, the steps below can guide you through the manual process of getting set to run `ansible-navigator` without a `cldr-runner` _execution environment_.

## Install an Execution Environment

`ansible-navigator` typically runs within an _execution environment_ -- an `ansible-runner`-enabled container. To this end, you will need to have `docker` or an equivalent or `podman` running on your host.

### Docker

* [Windows](https://docs.docker.com/docker-for-windows/install/)
* [Mac](https://docs.docker.com/docker-for-mac/install/)
* Linux users, use your package manager

> [!WARNING]
> Be sure you uninstall any earlier versions of Docker, i.e. `docker`, and install the latest version, i.e. `docker-ce`. See [Install Docker Engine](https://docs.docker.com/engine/install/) for further details.

> [!NOTE]
> If you have not used Docker before, consider following their quick [Tutorial](https://docs.docker.com/get-started/#start-the-tutorial) to validate it is working and familiarize yourself with the interface.

## Install Git

> [!NOTE]
> Git is required if you intend to clone the software for local editing. If you just intend to run the automation tools, you may skip this step.

There are excellent instructions for installing Git on all Operating Systems on the [Git website](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

## Install AWS CLI

If you are going to be working with AWS, you will want the latest version of the **AWS CLI**.

* [Windows](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html)
* [Mac](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html)
* Linux users, use your package manager

If this is the first time you are installing the AWS CLI, configure the program by providing your credentials, and test that your credentials work

```bash
aws configure
aws iam get-user
```

Visit the [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) for further details regarding credential management.

## Install CDP CLI

Get the latest version of the **CDP CLI**.

* [Install CDP CLI](https://docs.cloudera.com/cdp/latest/cli/topics/mc-installing-cdp-client.html)

If this is the first time you are installing the CDP CLI, you will need to configure the program by providing the right credentials, and should then test that your credentials work.

```bash
cdp configure
cdp iam get-user
```

Visit the [CDP CLI User Guide](https://docs.cloudera.com/cdp/latest/cli/topics/mc-configuring-cdp-client-with-the-api-access-key.html) for further details regarding credential management.

## Confirm your SSH Keypair

Ensure that you have a generated SSH keypair for your local profile. Visit the [SSH Keygen How-To](https://www.ssh.com/academy/ssh/keygen) for details.

## Confirm your SSH Agent

Ensure that you have a properly configured SSH Agent. Visit the [SSH Agent How-To](https://www.ssh.com/academy/ssh/keygen#adding-the-key-to-ssh-agent) for details.
