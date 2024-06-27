# Frequently Asked Questions

Be sure to check out the [Discussions > Help](https://github.com/cloudera-labs/cldr-runner/discussions/categories/help) category for the latest answers.

# `ansible-navigator` FAQ

## How do I add _extra variables_ and tags to `ansible-navigator`?

If you want to run a playbook with a given tag, e.g. `-t infra`, then simply add it as a parameter to the `ansible-navigator` commandline. For example, `ansible-navigator run playbook.yml -t infra`.

Like tags, so you can pass _extra variables_ to `ansible-navigator` and the underlying Ansible command. For example, `ansible-navigator run playbook.yml -e @some_config.yml -e some_var=yes`.

## How do I tell `ansible-navigator` where to find collections and roles?

By default, `cloudera-deploy` expects to use the collections, roles, and libraries within the _execution environment_ container, that is, the `cldr-runner` image. Make sure you do _not_ have `ANSIBLE_COLLECTIONS_PATH` or `ANSIBLE_ROLES_PATH` set or `ansible-navigator` will pick up these environment variables and pass them to the running container. The underlying `ansible` application, like `ansible-playbook` will then pick up these environment variables and attempt to use them if set!

This behavior is great if you want to use host-based collections, e.g. local development, but you need to ensure that you update the `ansible-navigator.yml` configuration file to mount the host collection and/or role directories into the execution environment container. See [Advanced Usage: Execution Modes](NAVIGATOR.md#advanced-usage-execution-modes) to learn more about these execution modes.

## `ansible-navigator` hangs when I run my playbook. What is going on?

`ansible-navigator` does not handle user prompts when running in the `curses`, text-based UI , so actions in your playbook like:

* Vault passwords
* SSH passphrases
* Debugger statements

will not work out-of-the-box. You can enable `ansible-navigator` to run with prompts, but doing so will also disable the TUI and instead run its operations using `stdout`.

Try adding:

```bash
ansible-navigator run --enable-prompts ...
```

to your execution to allow `ansible-navigator` to receive your prompt input.

## How can I view a previous `ansible-navigator` run to debug an issue?

`ansible-navigator` can be configured to save execution runs to a directory. You can reload a run by using the `replay` command:

```bash
ansible-navigator replay <playbook execution run file>.json
```

Then you can use the TUI to review the plays, tasks, and inventory for the previous run!

You can learn more about [replays](https://ansible.readthedocs.io/projects/navigator/subcommands/#ansible-navigator-subcommands) and their [configuration](https://ansible.readthedocs.io/projects/navigator/settings/#subcommand-replay) in the `ansible-navigator` documentation.

## How can I enable the playbook debugger?

The [playbook debugger](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html) is enabled in `ansible-navigator` by setting the debugger and then enabling prompts. For example,

```bash
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-navigator run --enable-prompts main.yml
```

## How can I reference SSH keys when running in an Execution Environment container?

The [`ansible-navigator` documentation](https://ansible.readthedocs.io/projects/navigator/faq/#ssh-keys) has instructions and guidance for using SSH keys within an execution environment, including how `ansible-navigator` will volume mount the SSH authentication socket dictated by `SSH_AUTH_SOCK` and set the same within the container. However, some host services are unable to mount sockets, so the best way to reference a SSH private key is to specify the `ansible_ssh_private_key_file` variable for a given host inventory. (See the note in the above documentation link.)

For example, you might want to create a `group_vars/all.yml` or `group_vars/<inventory group name>.yml` file and specify the `ansible_ssh_private_key_file`.

In any event, when specifying the `ansible_ssh_private_key_file`, keep in mind the path to the referenced key is in relation to the location of the key _within the execution environment_! (Again, see the above documentation link.)

## How to I configure SSH to avoid a "Failed to connect to new control master" error?

When running connecting to a host via SSH while running `ansible-navigator`, in particular when you are working with Terraform inventory managed by the `cloud.terraform` inventory plugin, you might encounter the following error:

```bash
Failed to connect to the host via ssh: Control socket connect(/runner/.ansible/cp/b44b170fff): Connection refused
Failed to connect to new control master
```

To resolve, be sure to add the following variable to your `ansible-navigator.yml` configuration file:

```yaml
ansible-navigator:
  execution-environment:
    environment-variables:
      set:
        ANSIBLE_SSH_CONTROL_PATH: "/dev/shm/cp%%h-%%p-%%r"
```
