# Installing, Running, Managing, and Troubleshooting `ansible-navigator`

> `ansible-navigator` is a command-line tool and a text-based user interface (TUI) for creating, reviewing, running and troubleshooting Ansible content, including inventories, playbooks, collections, documentation and container images (execution environments).

## Installation

Setting up `ansible-navigator` is easy; you can spin up a new setup in **TWO** steps (see note below for important details)!

1. Create and activate a new `virtualenv`.

   You can name your virtual environment anything you want; by convention, we like to call it `cdp-navigator`.

   ```bash
   python -m venv ~/cdp-navigator; source ~/cdp-navigator/bin/activate;
   ```

2. Install the latest `ansible-core` and `ansible-navigator`.

   The version of these tools can be the latest, as the actual execution version are encapsulated in the _execution environment_ container.

   ```bash
    pip install ansible-core ansible-navigator
   ```

Read more about [installing `ansible-navigator`](https://ansible.readthedocs.io/projects/navigator/installation/#install-ansible-navigator).

> [!IMPORTANT]
> Please note each OS has slightly different requirements for installing `ansible-navigator`. :woozy_face:

## Usage

`ansible-navigator` can be viewed as a wrapper around the core Ansible application, like `ansible-playbook`, `ansible-galaxy`, `ansible-doc`, etc. Read more about how to [configure](https://ansible.readthedocs.io/projects/navigator/settings/) your setup and your project execution as well as the [mapping](https://ansible.readthedocs.io/projects/navigator/subcommands/#mapping-ansible-navigator-commands-to-ansible-commands) of and [running](https://ansible.readthedocs.io/projects/navigator/subcommands/) of these subcommands.

### Common commands

| Command | Description |
|---------|-------------|
| `ansible-navigator run main.yml -e @config.yml` | Run the `main.yml` playbook with the contents of `config.yml` loaded as _extra variables_. |
| `ansible-navigator doc cloudera.cloud.env_info` | View the `ansible-docs` of the [`cloudera.cloud.env_info` module](https://cloudera-labs.github.io/cloudera.cloud/env_info_module.html). |
| `ansible-navigator doc cloudera.cloud.datahub_service -t lookup` | View the `ansible-docs` of the [`cloudera.cloud.datahub_service` lookup](https://wmudge.github.io/cloudera.cloud/datahub_service_lookup.html) plugin. |
| `ansible-navigator exec -- ansible localhost -m cloudera.cloud.env_info -a 'name=my_env'` | Query the Cloudera Data Platform (CDP) Public Cloud for details on the `my_env` Environment. |

## Advanced Usage: Execution Modes

`ansible-navigator` typically executes Ansible using the Ansible runtime, collections, and roles built into the _execution environment_, but this is not the only way you can use the tool. In fact, there are **four** modes of execution with `ansible-navigator`, each providing a growing degree of control and customization as well as complexity. Yet, `ansible-navigator` provides a common interface to all modes, allowing you to switch seamlessly from one mode to another.

Each mode is enabled by the presence of certain paths (e.g. `ANSIBLE_COLLECTIONS_PATHS`, `./collections`) and configuration parameters (e.g. `--execution-environment`).

### User Mode

| Collections path | Ansible runtime |
|------------------|-----------------|
| container | container |

This is the default mode for using _execution environments_ like `cldr-runner`. All executable assets and dependencies are bundled into the image. All that is needed to run is `ansible-navigator` itself; the tool will collect and inject everything into the running container.

### Power User Mode

| Collections path | Ansible runtime |
|------------------|-----------------|
| project | container |

If `ansible-navigator` discovers a `./collections` directory in the project, it will mount that directory into the running container and set the in-container Ansible configuration to use it. This allows you to develop and work with collections locally to a project. You can install local collections by using the `-p` flag with `ansible-galaxy`, for example, `ansible-galaxy collections install community.crypto -p ./collections`. Typically, you might keep a local `./collection/requirements.yml` configuration and install via `ansible-galaxy`.  `ansible-navigator` still uses the container for execution.

See the [Placement of Ansible collections](https://ansible.readthedocs.io/projects/navigator/faq/#placement-of-ansible-collections) section for further details.

### Developer Mode

| Collections path | Ansible runtime |
|------------------|-----------------|
| host | container |

In this mode, you set the `ANSIBLE_COLLECTIONS_PATH` environment variable in your host's shell, pointing at a host-installed, Ansible collections directory and specify the mount path in the `ansible-navigator.yml` configuration. `ansible-navigator` automatically sets this environment variable in the container, which now points to the custom mounted directory. For example:

```yaml
ansible-navigator:
  execution-environment:
    volume-mounts:
      - src: "${ANSIBLE_COLLECTIONS_PATH}"
        dest: "${ANSIBLE_COLLECTIONS_PATH}"
        options: "Z"
```

Typically, this collections directory is a mix of Git-cloned and downloaded collections; the former grants you full SCM control. Meanwhile, `ansible-navigator` still uses the container for execution.

See the [Placement of Ansible collections](https://ansible.readthedocs.io/projects/navigator/faq/#placement-of-ansible-collections) section for further details.

The [local development](README.md#local-development) instructions are designed to support this mode. 

### Platform Mode

| Collections path | Ansible runtime |
|------------------|-----------------|
| host (or project) | host |

In this final mode, you set both the `ANSIBLE_COLLECTIONS_PATH` to a host-installed collections directory (or use `./collections`) **and** disable the _execution engine_ parameter in the `ansible-navigator.yml` configuration. `ansible-navigator` automatically sets the environment variable yet runs the commands using the host system, not the container runtimes.

```yaml
ansible-navigator:
  execution-environment:
      enabled: False
```

> [!NOTE]
> You can set this parameter via the CLI flags, `--ee` or `--execution-environment`.

Arguably, this mode is the most complex, as it requires you to have installed all the Python and system dependencies on your host system; `ansible-navigator` only does the organization and coordination of assets and command, ignoring the container completely.

See the [Execution Environment configuration](https://ansible.readthedocs.io/projects/navigator/settings/#execution-environment) section for further details.

This is a fairly common task then [running CI jobs](https://github.com/cloudera-labs/cloudera.cluster/blob/main/.github/workflows/validate_pr.yml) for individual collections. The [local development](README.md#local-development) instructions are designed to support this mode.

## Troubleshooting

The [Frequently Asked Questions](FAQ.md) guide has a collection of relevant troubleshooting topics. You can also stop by the [Discussion > Help](https://github.com/cloudera-labs/cldr-runner/discussions/categories/help) category for the latest answers.
