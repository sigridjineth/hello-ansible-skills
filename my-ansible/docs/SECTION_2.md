# Section 2: Inventory & Configuration

## Table of Contents
- [Understanding Inventory](#understanding-inventory)
- [Inventory File Formats](#inventory-file-formats)
- [Host Groups](#host-groups)
- [Host and Group Variables](#host-and-group-variables)
- [ansible.cfg Configuration](#ansiblecfg-configuration)
- [Practical Examples](#practical-examples)
- [Best Practices](#best-practices)

---

## Understanding Inventory

The **inventory** is the foundation of Ansible - it defines **what** machines Ansible will manage.

### What is an Inventory?

```
┌─────────────────────────────────────────────────────────────────┐
│                        INVENTORY CONCEPT                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  INVENTORY FILE                    REAL INFRASTRUCTURE          │
│  ┌─────────────────┐              ┌─────────────────────────┐  │
│  │                 │              │                         │  │
│  │ [webservers]    │    ──────►   │  ┌─────┐    ┌─────┐    │  │
│  │ web1.example.com│              │  │web1 │    │web2 │    │  │
│  │ web2.example.com│              │  └─────┘    └─────┘    │  │
│  │                 │              │                         │  │
│  │ [databases]     │    ──────►   │  ┌─────┐    ┌─────┐    │  │
│  │ db1.example.com │              │  │ db1 │    │ db2 │    │  │
│  │ db2.example.com │              │  └─────┘    └─────┘    │  │
│  │                 │              │                         │  │
│  └─────────────────┘              └─────────────────────────┘  │
│                                                                  │
│  Inventory tells Ansible:                                       │
│  • Which hosts exist                                            │
│  • How to group them                                            │
│  • How to connect to them                                       │
│  • What variables apply to them                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Default Inventory Location

Ansible looks for inventory in these locations (in order):

1. `-i` command line option: `ansible -i /path/to/inventory`
2. `ANSIBLE_INVENTORY` environment variable
3. `ansible.cfg` configuration: `inventory = ./inventory`
4. Default: `/etc/ansible/hosts`

---

## Inventory File Formats

Ansible supports two primary formats: **INI** and **YAML**.

### INI Format (Traditional)

```ini
# inventory (INI format)

# Simple host list
server1.example.com
server2.example.com

# Grouped hosts
[webservers]
web1.example.com
web2.example.com
web3.example.com

[databases]
db1.example.com
db2.example.com

# Host with connection details
[loadbalancers]
lb1.example.com ansible_host=192.168.1.100 ansible_port=2222

# Ranges (web[01:10] expands to web01, web02, ... web10)
[app_servers]
app[01:05].example.com

# Localhost with local connection
[local]
localhost ansible_connection=local
```

### YAML Format (Modern)

```yaml
# inventory.yml (YAML format)
all:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
        web3.example.com:

    databases:
      hosts:
        db1.example.com:
          ansible_host: 192.168.1.50
        db2.example.com:
          ansible_host: 192.168.1.51

    loadbalancers:
      hosts:
        lb1.example.com:
          ansible_host: 192.168.1.100
          ansible_port: 2222
```

### Format Comparison

| Feature | INI | YAML |
|---------|-----|------|
| Readability | Simple for small inventories | Better for complex structures |
| Nesting | Limited | Full support |
| Variables | Inline or separate sections | Inline with full structure |
| Comments | `#` or `;` | `#` only |
| Recommended for | Small/medium projects | Large/complex projects |

---

## Host Groups

Groups organize hosts logically, allowing you to target multiple servers with one command.

### Basic Groups

```ini
# Functional groups
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com
db2.example.com

[caches]
redis1.example.com
redis2.example.com
```

### Nested Groups (Groups of Groups)

```ini
# Parent group containing child groups
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com

# Create a group from other groups
[production:children]
webservers
databases

# Environment-based grouping
[staging:children]
staging_web
staging_db

[staging_web]
staging-web1.example.com

[staging_db]
staging-db1.example.com
```

### Visual Representation

```
┌─────────────────────────────────────────────────────────────────┐
│                      GROUP HIERARCHY                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                           all                                    │
│                            │                                     │
│          ┌─────────────────┼─────────────────┐                  │
│          │                 │                 │                  │
│          ▼                 ▼                 ▼                  │
│    ┌──────────┐     ┌──────────┐     ┌──────────┐              │
│    │production│     │ staging  │     │   dev    │              │
│    └────┬─────┘     └────┬─────┘     └────┬─────┘              │
│         │                │                │                     │
│    ┌────┴────┐      ┌────┴────┐      ┌────┴────┐               │
│    │         │      │         │      │         │               │
│    ▼         ▼      ▼         ▼      ▼         ▼               │
│ ┌─────┐  ┌─────┐ ┌─────┐  ┌─────┐ ┌─────┐  ┌─────┐            │
│ │ web │  │ db  │ │ web │  │ db  │ │ web │  │ db  │            │
│ └──┬──┘  └──┬──┘ └──┬──┘  └──┬──┘ └──┬──┘  └──┬──┘            │
│    │        │       │        │       │        │                │
│  web1     db1    s-web1   s-db1   d-web1   d-db1              │
│  web2     db2                                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Special Groups

Ansible has two built-in groups:

| Group | Description |
|-------|-------------|
| `all` | Contains every host in the inventory |
| `ungrouped` | Contains hosts not in any explicit group |

```bash
# Target all hosts
ansible all -m ping

# Target ungrouped hosts only
ansible ungrouped -m ping
```

---

## Host and Group Variables

Variables can be assigned to hosts and groups directly in inventory or in separate files.

### Inline Variables (INI)

```ini
[webservers]
web1.example.com http_port=80 max_clients=200
web2.example.com http_port=8080 max_clients=100

[databases]
db1.example.com db_port=5432 db_name=production
db2.example.com db_port=5432 db_name=replica

# Group variables (apply to all hosts in group)
[webservers:vars]
nginx_version=1.18
document_root=/var/www/html

[databases:vars]
postgres_version=14
backup_enabled=true

# Variables for 'all' group (apply to every host)
[all:vars]
ansible_user=admin
ansible_python_interpreter=/usr/bin/python3
```

### Separate Variable Files (Recommended)

For larger projects, use directory structure:

```
inventory/
├── hosts                 # Main inventory file
├── group_vars/
│   ├── all.yml          # Variables for all hosts
│   ├── webservers.yml   # Variables for webservers group
│   └── databases.yml    # Variables for databases group
└── host_vars/
    ├── web1.example.com.yml  # Variables for specific host
    └── db1.example.com.yml   # Variables for specific host
```

**group_vars/all.yml:**
```yaml
---
# Variables for all hosts
ansible_user: admin
ntp_server: time.example.com
timezone: UTC
```

**group_vars/webservers.yml:**
```yaml
---
# Variables for webservers group
http_port: 80
nginx_version: "1.18"
document_root: /var/www/html
ssl_enabled: true
```

**host_vars/web1.example.com.yml:**
```yaml
---
# Variables specific to web1
http_port: 8080  # Override group default
ssl_certificate: /etc/ssl/web1.crt
```

### Variable Precedence (Low to High)

```
┌─────────────────────────────────────────────────────────────────┐
│              VARIABLE PRECEDENCE (Lowest to Highest)            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. role defaults (roles/x/defaults/main.yml)     ← LOWEST     │
│  2. inventory file or script group vars                         │
│  3. inventory group_vars/all                                    │
│  4. playbook group_vars/all                                     │
│  5. inventory group_vars/*                                      │
│  6. playbook group_vars/*                                       │
│  7. inventory file or script host vars                          │
│  8. inventory host_vars/*                                       │
│  9. playbook host_vars/*                                        │
│  10. host facts                                                 │
│  11. play vars                                                  │
│  12. play vars_prompt                                           │
│  13. play vars_files                                            │
│  14. role vars (roles/x/vars/main.yml)                         │
│  15. block vars (for tasks in block)                           │
│  16. task vars (only for the task)                             │
│  17. include_vars                                               │
│  18. set_facts / registered vars                               │
│  19. role parameters                                            │
│  20. include parameters                                         │
│  21. extra vars (-e "key=value")                  ← HIGHEST    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Simplified Rule**: Extra vars (`-e`) always win!

---

## ansible.cfg Configuration

The `ansible.cfg` file controls Ansible's behavior.

### Configuration File Locations (Priority Order)

1. `ANSIBLE_CONFIG` environment variable
2. `./ansible.cfg` (current directory) ← **Recommended for projects**
3. `~/.ansible.cfg` (home directory)
4. `/etc/ansible/ansible.cfg` (system-wide)

### Our Lab Configuration

```ini
# ansible.cfg
[defaults]
inventory = ./inventory                    # Default inventory file
remote_user = root                         # Default SSH user
ask_pass = false                           # Don't prompt for SSH password
host_key_checking = false                  # Skip SSH host key verification
interpreter_python = auto_silent           # Auto-detect Python, suppress warnings

[privilege_escalation]
become = false                             # Don't use sudo by default
become_method = sudo                       # Use sudo when become=true
become_user = root                         # Become root when escalating
become_ask_pass = false                    # Don't prompt for sudo password
```

### Common Configuration Options

#### [defaults] Section

| Option | Description | Example |
|--------|-------------|---------|
| `inventory` | Default inventory path | `./inventory` |
| `remote_user` | Default SSH user | `ansible` |
| `ask_pass` | Prompt for SSH password | `false` |
| `host_key_checking` | Verify SSH host keys | `false` |
| `forks` | Parallel connections | `10` |
| `timeout` | SSH timeout (seconds) | `30` |
| `log_path` | Log file location | `/var/log/ansible.log` |
| `roles_path` | Where to find roles | `./roles:/etc/ansible/roles` |
| `retry_files_enabled` | Create .retry files | `false` |
| `stdout_callback` | Output format | `yaml` |

#### [privilege_escalation] Section

| Option | Description | Example |
|--------|-------------|---------|
| `become` | Enable privilege escalation | `true` |
| `become_method` | Method (sudo, su, pbrun, etc.) | `sudo` |
| `become_user` | User to become | `root` |
| `become_ask_pass` | Prompt for become password | `false` |

### Production Configuration Example

```ini
# ansible.cfg for production
[defaults]
inventory = ./inventory/production
remote_user = deploy
ask_pass = false
host_key_checking = true          # Enable in production!
forks = 20                        # More parallel connections
timeout = 30
log_path = /var/log/ansible.log
retry_files_enabled = true
stdout_callback = yaml            # Pretty YAML output

[privilege_escalation]
become = true                     # Usually need sudo in production
become_method = sudo
become_user = root
become_ask_pass = false

[ssh_connection]
pipelining = true                 # Faster execution
control_path = /tmp/ansible-%%h-%%r  # SSH multiplexing
```

---

## Practical Examples

### Our Lab Inventory

```ini
# inventory
[web]
localhost ansible_connection=local ansible_python_interpreter=/opt/homebrew/bin/python3

[db]
localhost ansible_connection=local ansible_python_interpreter=/opt/homebrew/bin/python3

[all:children]
web
db

[all:vars]
user=ansible_user
```

**Line-by-line explanation:**

```ini
[web]
# Creates a group named "web"

localhost ansible_connection=local ansible_python_interpreter=/opt/homebrew/bin/python3
# localhost: the target host (our local machine)
# ansible_connection=local: use local connection instead of SSH
# ansible_python_interpreter: explicit Python path for macOS

[db]
# Creates a group named "db"
localhost ansible_connection=local ansible_python_interpreter=/opt/homebrew/bin/python3
# Same host can be in multiple groups

[all:children]
# Define a group containing other groups
web
db
# "all" now explicitly includes both "web" and "db"

[all:vars]
# Variables that apply to all hosts
user=ansible_user
# This variable is available in all playbooks
```

### Verify Inventory

```bash
# List all hosts
$ ansible-inventory --list -y
all:
  children:
    db:
      hosts:
        localhost:
          ansible_connection: local
          ansible_python_interpreter: /opt/homebrew/bin/python3
          user: ansible_user
    web:
      hosts:
        localhost:
          ansible_connection: local
          ansible_python_interpreter: /opt/homebrew/bin/python3
          user: ansible_user

# Show inventory graph
$ ansible-inventory --graph
@all:
  |--@db:
  |  |--localhost
  |--@web:
  |  |--localhost

# List hosts in specific group
$ ansible webservers --list-hosts
  hosts (1):
    localhost
```

---

## Best Practices

### 1. Use Meaningful Group Names

```ini
# Good - descriptive names
[webservers]
[databases]
[loadbalancers]
[monitoring]

# Bad - vague names
[group1]
[servers]
[misc]
```

### 2. Use Multiple Grouping Strategies

```ini
# By function
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com

# By environment
[production]
web1.example.com
db1.example.com

[staging]
staging-web.example.com
staging-db.example.com

# By location
[datacenter_east]
web1.example.com
db1.example.com

[datacenter_west]
web2.example.com
```

### 3. Separate Variables from Inventory

```
# Recommended structure
project/
├── ansible.cfg
├── inventory/
│   ├── production
│   ├── staging
│   └── development
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── databases.yml
├── host_vars/
│   └── special-server.yml
└── playbooks/
    └── site.yml
```

### 4. Use Inventory Patterns

```bash
# Target multiple groups
ansible 'webservers:databases' -m ping

# Target intersection (hosts in BOTH groups)
ansible 'webservers:&production' -m ping

# Exclude a group
ansible 'all:!staging' -m ping

# Complex patterns
ansible 'webservers:databases:&production:!maintenance' -m ping
```

---

## Summary

In this section, you learned:

1. **Inventory basics**: Defining hosts and groups
2. **File formats**: INI vs YAML
3. **Groups**: Basic, nested, and special groups
4. **Variables**: Host vars, group vars, and precedence
5. **ansible.cfg**: Configuration options and locations
6. **Best practices**: Organization and patterns

---

## Next Steps

Continue to [Section 3: Ad-hoc Commands & First Playbook](./SECTION_3.md) to start executing commands and writing playbooks.

---

## Quick Reference

```bash
# Inventory commands
ansible-inventory --list              # Show full inventory
ansible-inventory --graph             # Show inventory tree
ansible all --list-hosts              # List all hosts
ansible webservers --list-hosts       # List hosts in group

# Target patterns
ansible all -m ping                   # All hosts
ansible webservers -m ping            # Single group
ansible 'web:db' -m ping              # Multiple groups
ansible 'web:&prod' -m ping           # Intersection
ansible 'all:!staging' -m ping        # Exclusion
```
