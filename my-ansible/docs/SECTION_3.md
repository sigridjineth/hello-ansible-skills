# Section 3: Ad-hoc Commands & First Playbook

## Table of Contents
- [Ad-hoc Commands](#ad-hoc-commands)
- [Understanding Modules](#understanding-modules)
- [Common Modules](#common-modules)
- [Your First Playbook](#your-first-playbook)
- [Playbook Structure](#playbook-structure)
- [Running Playbooks](#running-playbooks)
- [Practical Examples](#practical-examples)

---

## Ad-hoc Commands

Ad-hoc commands are **one-liner Ansible commands** for quick tasks without writing a playbook.

### When to Use Ad-hoc Commands

| Use Case | Example |
|----------|---------|
| Quick checks | `ansible all -m ping` |
| Gathering info | `ansible all -m setup` |
| One-time tasks | `ansible all -m shell -a "uptime"` |
| Emergency fixes | `ansible all -m service -a "name=nginx state=restarted"` |
| Testing | Verifying connectivity before running playbooks |

### Ad-hoc Command Syntax

```
┌─────────────────────────────────────────────────────────────────┐
│                   AD-HOC COMMAND STRUCTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ansible [pattern] -m [module] -a "[arguments]" [options]       │
│                                                                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────────────────────┐ │
│  │ pattern │ │ module  │ │  args   │ │       options         │ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └───────────┬───────────┘ │
│       │           │           │                   │             │
│       │           │           │                   │             │
│       ▼           ▼           ▼                   ▼             │
│   Which hosts   What to do  How to do it    Extra settings     │
│   to target                                                     │
│                                                                  │
│  Example:                                                       │
│  ansible webservers -m shell -a "uptime" -i inventory          │
│          ─────────    ─────    ────────   ───────────          │
│          pattern      module   arguments  inventory file       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Basic Ad-hoc Examples

```bash
# 1. Ping all hosts (test connectivity)
$ ansible all -m ping
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

# 2. Run shell command
$ ansible all -m shell -a "hostname"
localhost | CHANGED | rc=0 >>
MacBook-Pro.local

# 3. Get system uptime
$ ansible all -m shell -a "uptime"
localhost | CHANGED | rc=0 >>
15:30  up 5 days,  3:45, 2 users, load averages: 1.25 1.40 1.35

# 4. Check disk space
$ ansible all -m shell -a "df -h"
localhost | CHANGED | rc=0 >>
Filesystem      Size   Used  Avail Capacity  Mounted on
/dev/disk1s1   466Gi  150Gi  300Gi    34%    /

# 5. Create a file
$ ansible all -m file -a "path=/tmp/test.txt state=touch"
localhost | CHANGED => {
    "changed": true,
    "dest": "/tmp/test.txt",
    "mode": "0644"
}

# 6. Copy content to file
$ ansible all -m copy -a "content='Hello World' dest=/tmp/hello.txt"
localhost | CHANGED => {
    "changed": true,
    "dest": "/tmp/hello.txt"
}
```

### Ad-hoc Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `-m` | Module name | `-m ping`, `-m shell` |
| `-a` | Module arguments | `-a "uptime"` |
| `-i` | Inventory file | `-i ./inventory` |
| `-u` | Remote user | `-u admin` |
| `-b` | Become (sudo) | `-b` |
| `-K` | Ask for sudo password | `-K` |
| `-k` | Ask for SSH password | `-k` |
| `-f` | Forks (parallelism) | `-f 10` |
| `-v` | Verbose output | `-v`, `-vv`, `-vvv` |

---

## Understanding Modules

Modules are the **building blocks** of Ansible. Each module performs a specific task.

### Module Categories

```
┌─────────────────────────────────────────────────────────────────┐
│                      MODULE CATEGORIES                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │    System      │  │    Commands    │  │     Files      │    │
│  ├────────────────┤  ├────────────────┤  ├────────────────┤    │
│  │ • user         │  │ • command      │  │ • file         │    │
│  │ • group        │  │ • shell        │  │ • copy         │    │
│  │ • service      │  │ • raw          │  │ • template     │    │
│  │ • cron         │  │ • script       │  │ • lineinfile   │    │
│  │ • hostname     │  │ • expect       │  │ • fetch        │    │
│  └────────────────┘  └────────────────┘  └────────────────┘    │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │   Packaging    │  │   Database     │  │     Cloud      │    │
│  ├────────────────┤  ├────────────────┤  ├────────────────┤    │
│  │ • apt          │  │ • mysql_db     │  │ • ec2          │    │
│  │ • yum          │  │ • mysql_user   │  │ • azure_rm_*   │    │
│  │ • dnf          │  │ • postgresql_* │  │ • gcp_*        │    │
│  │ • pip          │  │ • mongodb_*    │  │ • docker_*     │    │
│  │ • gem          │  │ • redis        │  │ • k8s          │    │
│  └────────────────┘  └────────────────┘  └────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Module Documentation

```bash
# List all modules
ansible-doc -l | head -20

# Get help for specific module
ansible-doc file

# Show module examples
ansible-doc -s file
```

---

## Common Modules

### 1. ping Module
Tests connectivity (not ICMP ping, just Ansible communication).

```bash
# Test all hosts
ansible all -m ping

# Output:
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 2. shell Module
Executes shell commands on remote hosts.

```bash
# Run any shell command
ansible all -m shell -a "echo $HOME"
ansible all -m shell -a "cat /etc/passwd | grep root"
ansible all -m shell -a "ls -la /tmp"
```

**Note**: Use `command` module for simple commands (more secure, no shell features):
```bash
ansible all -m command -a "ls /tmp"
# command module doesn't support pipes, redirects, or shell variables
```

### 3. file Module
Manages files, directories, and links.

```bash
# Create directory
ansible all -m file -a "path=/tmp/mydir state=directory mode=0755"

# Create empty file
ansible all -m file -a "path=/tmp/myfile state=touch"

# Delete file
ansible all -m file -a "path=/tmp/myfile state=absent"

# Create symbolic link
ansible all -m file -a "src=/etc/hosts dest=/tmp/hosts_link state=link"
```

### 4. copy Module
Copies files from control node to managed nodes.

```bash
# Copy file
ansible all -m copy -a "src=./local.txt dest=/tmp/remote.txt"

# Copy with content
ansible all -m copy -a "content='Hello World\n' dest=/tmp/hello.txt"

# Copy with permissions
ansible all -m copy -a "src=./script.sh dest=/tmp/script.sh mode=0755"
```

### 5. debug Module
Prints messages or variable values (useful for debugging).

```bash
# Print message
ansible all -m debug -a "msg='Hello from Ansible'"

# Print variable
ansible all -m debug -a "var=ansible_hostname"
```

---

## Your First Playbook

A **playbook** is a YAML file that defines a set of tasks to execute.

### Playbook Anatomy

```yaml
# first-playbook.yml
---                              # YAML document start
- name: My First Playbook        # Play name (description)
  hosts: all                     # Target hosts

  tasks:                         # List of tasks
    - name: Print message        # Task name
      debug:                     # Module name
        msg: Hello Ansible!      # Module argument
```

### Line-by-Line Explanation

```yaml
---
# ^^^ Three dashes indicate start of YAML document
# Required at the beginning of every playbook

- name: My First Playbook
# ^^^ A play begins with a dash (-)
# "name" is optional but recommended for readability
# This describes what the play does

  hosts: all
# ^^^ REQUIRED: Which hosts to target
# Can be: all, group name, host name, or pattern

  tasks:
# ^^^ List of tasks to execute (in order)

    - name: Print message
#   ^^^ Each task starts with a dash
#   "name" describes the task (shown during execution)

      debug:
#     ^^^ The Ansible module to use

        msg: Hello Ansible!
#       ^^^ Module argument
#       Each module has different arguments
```

### Running Your First Playbook

```bash
# Create the playbook
cat > first-playbook.yml << 'EOF'
---
- hosts: all
  tasks:
    - name: Print message
      debug:
        msg: Hello CloudNet@ Ansible Study
EOF

# Run the playbook
$ ansible-playbook first-playbook.yml

PLAY [all] *********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Print message] ***********************************************************
ok: [localhost] => {
    "msg": "Hello CloudNet@ Ansible Study"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Understanding the Output

```
┌─────────────────────────────────────────────────────────────────┐
│                    PLAYBOOK OUTPUT EXPLAINED                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PLAY [all]                                                     │
│  └── Starting play targeting "all" hosts                        │
│                                                                  │
│  TASK [Gathering Facts]                                         │
│  └── Automatic task collecting system information               │
│      ok: [localhost]                                            │
│      └── Task succeeded, no changes made                        │
│                                                                  │
│  TASK [Print message]                                           │
│  └── Our custom task                                            │
│      ok: [localhost] => {"msg": "Hello..."}                     │
│      └── Output from debug module                               │
│                                                                  │
│  PLAY RECAP                                                     │
│  └── Summary of execution                                       │
│      localhost: ok=2 changed=0 unreachable=0 failed=0          │
│                 │     │         │            │                  │
│                 │     │         │            └── Tasks failed   │
│                 │     │         └── Connection failed          │
│                 │     └── Tasks that made changes              │
│                 └── Tasks completed successfully               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Playbook Structure

### Complete Playbook Example

```yaml
---
# Playbook can contain multiple plays
- name: First Play - Configure Web Servers
  hosts: webservers           # Target group
  become: yes                 # Use sudo
  gather_facts: yes           # Collect system facts (default: yes)

  vars:                       # Play-level variables
    http_port: 80
    doc_root: /var/www/html

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: yes

- name: Second Play - Configure Databases
  hosts: databases
  become: yes

  tasks:
    - name: Install PostgreSQL
      apt:
        name: postgresql
        state: present
```

### Playbook Components

| Component | Required | Description |
|-----------|----------|-------------|
| `hosts` | Yes | Target hosts/groups |
| `tasks` | Yes* | List of tasks to execute |
| `name` | No | Description of play |
| `become` | No | Enable privilege escalation |
| `vars` | No | Define variables |
| `gather_facts` | No | Collect system facts (default: yes) |
| `handlers` | No | Tasks triggered by notify |
| `roles` | No | Include roles |

*Either `tasks` or `roles` is required

---

## Running Playbooks

### Basic Execution

```bash
# Run playbook
ansible-playbook playbook.yml

# Specify inventory
ansible-playbook -i inventory playbook.yml

# Limit to specific hosts
ansible-playbook playbook.yml --limit webservers

# Run with extra variables
ansible-playbook playbook.yml -e "version=1.0"
```

### Execution Options

| Option | Description | Example |
|--------|-------------|---------|
| `--check` | Dry run (don't make changes) | `ansible-playbook playbook.yml --check` |
| `--diff` | Show file differences | `ansible-playbook playbook.yml --diff` |
| `-v` | Verbose output | `-v`, `-vv`, `-vvv`, `-vvvv` |
| `--limit` | Limit to hosts/groups | `--limit webservers` |
| `-e` | Extra variables | `-e "var=value"` |
| `--tags` | Run only tagged tasks | `--tags "install,config"` |
| `--skip-tags` | Skip tagged tasks | `--skip-tags "test"` |
| `--list-tasks` | List tasks without running | `--list-tasks` |
| `--list-hosts` | List target hosts | `--list-hosts` |
| `--syntax-check` | Check syntax only | `--syntax-check` |

### Check Mode (Dry Run)

```bash
# See what would change without making changes
$ ansible-playbook playbook.yml --check

TASK [Create file] ************************************************************
changed: [localhost]  # Would change, but didn't (check mode)
```

### Diff Mode

```bash
# Show before/after for file changes
$ ansible-playbook playbook.yml --diff

TASK [Update config] **********************************************************
--- before: /etc/app/config.yml
+++ after: /etc/app/config.yml
@@ -1,3 +1,3 @@
-port: 8080
+port: 80
 debug: false
```

---

## Practical Examples

### Example 1: System Information Playbook

```yaml
# system-info.yml
---
- name: Gather System Information
  hosts: all

  tasks:
    - name: Display hostname
      debug:
        msg: "Hostname: {{ ansible_hostname }}"

    - name: Display OS
      debug:
        msg: "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"

    - name: Display IP address
      debug:
        msg: "IP: {{ ansible_default_ipv4.address | default('N/A') }}"

    - name: Display memory
      debug:
        msg: "Memory: {{ ansible_memtotal_mb }} MB"
```

### Example 2: File Management Playbook

```yaml
# file-management.yml
---
- name: File Management Demo
  hosts: all

  tasks:
    - name: Create project directory
      file:
        path: /tmp/myproject
        state: directory
        mode: '0755'

    - name: Create subdirectories
      file:
        path: "/tmp/myproject/{{ item }}"
        state: directory
      loop:
        - logs
        - config
        - data

    - name: Create config file
      copy:
        content: |
          # Application Configuration
          app_name: MyApp
          version: 1.0.0
          debug: true
        dest: /tmp/myproject/config/app.yml
        mode: '0644'

    - name: Verify structure
      shell: "find /tmp/myproject -type f -o -type d"
      register: result

    - name: Show structure
      debug:
        var: result.stdout_lines
```

### Example 3: Multi-task Playbook with Error Handling

```yaml
# robust-playbook.yml
---
- name: Robust Task Execution
  hosts: all

  tasks:
    - name: Task that might fail
      shell: "ls /nonexistent"
      ignore_errors: yes
      register: ls_result

    - name: Show failure info
      debug:
        msg: "Previous task failed: {{ ls_result.stderr }}"
      when: ls_result.failed

    - name: This always runs
      debug:
        msg: "Execution continues despite previous errors"
```

---

## Summary

In this section, you learned:

1. **Ad-hoc commands**: Quick one-liner tasks with `ansible` command
2. **Modules**: Building blocks like `ping`, `shell`, `file`, `copy`
3. **Playbooks**: YAML files defining automation tasks
4. **Playbook structure**: Plays, hosts, tasks, vars
5. **Running playbooks**: Basic execution and useful options
6. **Check/diff modes**: Safe ways to preview changes

---

## Next Steps

Continue to [Section 4: Variables](./SECTION_4.md) to learn how to make your playbooks dynamic and reusable.

---

## Quick Reference

```bash
# Ad-hoc commands
ansible all -m ping                     # Test connectivity
ansible all -m shell -a "uptime"        # Run command
ansible all -m file -a "path=/tmp/x state=touch"  # Create file

# Playbook commands
ansible-playbook playbook.yml           # Run playbook
ansible-playbook playbook.yml --check   # Dry run
ansible-playbook playbook.yml --diff    # Show changes
ansible-playbook playbook.yml -v        # Verbose
ansible-playbook playbook.yml --limit host1  # Limit hosts
```
