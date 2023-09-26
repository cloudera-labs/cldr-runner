# Frequently Asked Questions

Be sure to check out the [Discussions > Help](https://github.com/cloudera-labs/cldr-runner/discussions/categories/help) category for the latest answers. 

## `ansible-navigator` FAQ

### How to I add _extra variables_ and tags to `ansible-navigator`?

If you want to run a playbook with a given tag, e.g. `-t infra`, then simply add it as a parameter to the `ansible-navigator` commandline. For example, `ansible-navigator run playbook.yml -t infra`. 

Like tags, so you can pass _extra variables_ to `ansible-navigator` and the underlying Ansible command. For example, `ansible-navigator run playbook.yml -e @some_config.yml -e some_var=yes`.

### How do I tell `ansible-navigator` where to find collections and roles?

By default, `cloudera-deploy` expects to use the collections, roles, and libraries within the _execution environment_ container, that is `cldr-runner`. Make sure you do _not_ have `ANSIBLE_COLLECTIONS_PATH` or `ANSIBLE_ROLES_PATH` set or `ansible-navigator` will pick up these environment variables and pass them to the running container. The underlying `ansible` application, like `ansible-playbook` will then pick up these environment variables and attempt to use them if set! This behavior is great if you want to use host-based collections, e.g. local development, but you need to ensure that you update the `ansible-navigator.yml` configuration file to mount the host collection and/or role directories into the execution environment container.

### `ansible-navigator` hangs when I run my playbook. What is going on?

`ansible-navigator` does not handle user prompts when running in the `curses` UI, so actions in your playbook like:

* Vault passwords
* SSH passphrases
* Debugger statements

will not work out-of-the-box. You can enable `ansible-navigator` to run with prompts, but doing so will also disable the UI and instead run its operations using `stdout`.  Try adding:

```bash
ansible-navigator run --enable-prompts ...
```

to your execution.

### How can I view a previous `ansible-navigator` run to debug an issue?

Each example is configured to save execution runs in the project's `runs` directory. You can reload a run by using the `replay` command:

```bash
ansible-navigator replay runs/<playbook name>-<timestamp>.json
```

Then you can use the UI to review the plays, tasks, and inventory for the previous run!

### How can I enable the playbook debugger?

The [playbook debugger](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html) is enabled in `ansible-navigator` by setting the debugger and then enabling prompts. For example,

```bash
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-navigator run --enable-prompts main.yml
```

### How to I configure SSH to avoid a "Failed to connect to new control master" error?

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
