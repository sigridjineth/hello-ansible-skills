# Section 4: Variables

## Table of Contents
- [Introduction to Variables](#introduction-to-variables)
- [Variable Types](#variable-types)
- [Defining Variables](#defining-variables)
- [Variable Precedence](#variable-precedence)
- [Special Variables](#special-variables)
- [Registered Variables](#registered-variables)
- [Practical Examples](#practical-examples)
- [Best Practices](#best-practices)

---

## Introduction to Variables

Variables make playbooks **dynamic**, **reusable**, and **maintainable**.

### Why Use Variables?

```
┌─────────────────────────────────────────────────────────────────┐
│                    WITHOUT VARIABLES (BAD)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  # deploy-v1.yml           # deploy-v2.yml                      │
│  ---                       ---                                   │
│  - hosts: all              - hosts: all                         │
│    tasks:                    tasks:                             │
│      - name: Deploy          - name: Deploy                     │
│        copy:                   copy:                            │
│          src: app-1.0.jar      src: app-2.0.jar   ← DUPLICATED │
│          dest: /opt/app        dest: /opt/app                   │
│                                                                  │
│  Problem: Need separate files for each version!                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     WITH VARIABLES (GOOD)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  # deploy.yml                                                   │
│  ---                                                            │
│  - hosts: all                                                   │
│    tasks:                                                       │
│      - name: Deploy                                             │
│        copy:                                                    │
│          src: "app-{{ version }}.jar"   ← VARIABLE             │
│          dest: /opt/app                                         │
│                                                                  │
│  # Run with different versions:                                 │
│  ansible-playbook deploy.yml -e "version=1.0"                   │
│  ansible-playbook deploy.yml -e "version=2.0"                   │
│                                                                  │
│  Same playbook, different configurations!                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Variable Types

### Data Types in Ansible

Ansible variables support YAML data types:

```yaml
# String
username: admin
greeting: "Hello, World!"

# Number
http_port: 80
timeout: 30.5

# Boolean
debug_mode: true
ssl_enabled: false

# List (Array)
packages:
  - nginx
  - vim
  - git

# Dictionary (Map/Hash)
user:
  name: john
  uid: 1001
  groups:
    - wheel
    - docker

# Nested structures
database:
  primary:
    host: db1.example.com
    port: 5432
  replica:
    host: db2.example.com
    port: 5432
```

### Accessing Variables

```yaml
# Simple variable
msg: "User is {{ username }}"

# List access (zero-indexed)
first_package: "{{ packages[0] }}"        # nginx
second_package: "{{ packages[1] }}"       # vim

# Dictionary access (two syntaxes)
user_name: "{{ user.name }}"              # Dot notation
user_name: "{{ user['name'] }}"           # Bracket notation

# Nested access
primary_host: "{{ database.primary.host }}"
primary_port: "{{ database['primary']['port'] }}"

# With default value (if undefined)
optional_var: "{{ missing_var | default('fallback') }}"
```

---

## Defining Variables

### 1. Group Variables (group_vars)

Variables applied to all hosts in a group.

**Inventory inline:**
```ini
# inventory
[webservers]
web1.example.com
web2.example.com

[webservers:vars]
http_port=80
document_root=/var/www/html
```

**Separate file (recommended):**
```
project/
├── inventory
└── group_vars/
    ├── all.yml           # All hosts
    └── webservers.yml    # webservers group
```

```yaml
# group_vars/all.yml
---
ntp_server: time.example.com
timezone: UTC

# group_vars/webservers.yml
---
http_port: 80
document_root: /var/www/html
ssl_enabled: true
```

### 2. Host Variables (host_vars)

Variables for specific hosts.

**Inventory inline:**
```ini
[webservers]
web1.example.com http_port=8080
web2.example.com http_port=80
```

**Separate file:**
```
project/
├── inventory
└── host_vars/
    ├── web1.example.com.yml
    └── web2.example.com.yml
```

```yaml
# host_vars/web1.example.com.yml
---
http_port: 8080
ssl_certificate: /etc/ssl/web1.crt
special_config: true
```

### 3. Play Variables (vars)

Variables defined within a playbook.

```yaml
---
- hosts: webservers
  vars:                              # Play-level vars
    http_port: 80
    max_clients: 200

  tasks:
    - name: Show port
      debug:
        msg: "Port is {{ http_port }}"
```

### 4. vars_files

Load variables from external files.

```yaml
# vars/users.yml
---
user: ansible_admin
uid: 1001
groups:
  - wheel
  - docker

# playbook.yml
---
- hosts: all
  vars_files:
    - vars/users.yml

  tasks:
    - name: Show user
      debug:
        msg: "User {{ user }} with UID {{ uid }}"
```

### 5. Extra Variables (-e)

Variables passed at runtime (highest precedence).

```bash
# Single variable
ansible-playbook playbook.yml -e "version=2.0"

# Multiple variables
ansible-playbook playbook.yml -e "version=2.0 env=production"

# JSON format
ansible-playbook playbook.yml -e '{"version": "2.0", "debug": true}'

# From file
ansible-playbook playbook.yml -e "@vars.yml"
```

### 6. vars_prompt

Interactive variable input.

```yaml
---
- hosts: all
  vars_prompt:
    - name: username
      prompt: "Enter username"
      private: no                    # Show input

    - name: password
      prompt: "Enter password"
      private: yes                   # Hide input

  tasks:
    - name: Show input
      debug:
        msg: "Creating user {{ username }}"
```

---

## Variable Precedence

Understanding **which variable wins** when defined in multiple places.

### Precedence Hierarchy (Lowest to Highest)

```
┌─────────────────────────────────────────────────────────────────┐
│              VARIABLE PRECEDENCE (22 Levels!)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  LOWEST PRECEDENCE (easily overridden)                          │
│  ─────────────────────────────────────                          │
│  1.  command line values (e.g., -u my_user)                     │
│  2.  role defaults (roles/x/defaults/main.yml)                  │
│  3.  inventory file or script group vars                        │
│  4.  inventory group_vars/all                                   │
│  5.  playbook group_vars/all                                    │
│  6.  inventory group_vars/*                                     │
│  7.  playbook group_vars/*                                      │
│                                                                  │
│  MEDIUM PRECEDENCE                                              │
│  ─────────────────                                              │
│  8.  inventory file or script host vars                         │
│  9.  inventory host_vars/*                                      │
│  10. playbook host_vars/*                                       │
│  11. host facts / cached set_facts                              │
│  12. play vars                                                  │
│  13. play vars_prompt                                           │
│  14. play vars_files                                            │
│  15. role vars (roles/x/vars/main.yml)                         │
│  16. block vars                                                 │
│  17. task vars                                                  │
│                                                                  │
│  HIGHEST PRECEDENCE (hard to override)                          │
│  ─────────────────────────────────────                          │
│  18. include_vars                                               │
│  19. set_facts / registered vars                               │
│  20. role parameters                                            │
│  21. include parameters                                         │
│  22. extra vars (-e)                          ← ALWAYS WINS    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Simplified Mental Model

```
LOWEST                                                      HIGHEST
   │                                                            │
   ▼                                                            ▼
┌──────┐  ┌────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐  ┌──────┐
│ Role │→ │ Group  │→ │  Host   │→ │  Play   │→ │ Task/  │→ │ -e   │
│ Def. │  │  Vars  │  │  Vars   │  │  Vars   │  │ Set_F  │  │      │
└──────┘  └────────┘  └─────────┘  └─────────┘  └────────┘  └──────┘

Extra vars (-e) ALWAYS win!
```

### Precedence Example

```yaml
# group_vars/all.yml
http_port: 80

# host_vars/web1.yml
http_port: 8080

# playbook.yml
---
- hosts: web1
  vars:
    http_port: 9000

  tasks:
    - name: Show port
      debug:
        msg: "{{ http_port }}"  # Shows 9000 (play vars > host vars)

# Command line
ansible-playbook playbook.yml -e "http_port=3000"
# Now shows 3000 (extra vars > everything)
```

---

## Special Variables

Ansible provides built-in "magic" variables.

### Host and Group Variables

| Variable | Description |
|----------|-------------|
| `inventory_hostname` | Name of current host (as in inventory) |
| `ansible_host` | Actual host to connect to |
| `groups` | Dict of all groups and their hosts |
| `group_names` | List of groups current host belongs to |
| `hostvars` | Dict of all host variables |

```yaml
tasks:
  - name: Show inventory hostname
    debug:
      msg: "Running on {{ inventory_hostname }}"

  - name: Show all web servers
    debug:
      msg: "Web servers: {{ groups['webservers'] }}"

  - name: Show my groups
    debug:
      msg: "I belong to: {{ group_names }}"

  - name: Access another host's variable
    debug:
      msg: "DB host port: {{ hostvars['db1']['db_port'] }}"
```

### Play Context Variables

| Variable | Description |
|----------|-------------|
| `playbook_dir` | Directory of the playbook |
| `role_path` | Path to current role |
| `ansible_play_hosts` | List of hosts in current play |
| `ansible_play_batch` | Current batch of hosts |

---

## Registered Variables

Capture **output from tasks** for later use.

### Basic Registration

```yaml
---
- hosts: all
  tasks:
    - name: Run command
      shell: "hostname"
      register: hostname_result     # Store output

    - name: Show result
      debug:
        var: hostname_result        # Full result object

    - name: Show just stdout
      debug:
        msg: "Hostname is {{ hostname_result.stdout }}"
```

### Registered Variable Structure

```yaml
# What 'register' captures:
hostname_result:
  changed: true                     # Did task change anything?
  cmd: "hostname"                   # Command that was run
  rc: 0                            # Return code (0 = success)
  stdout: "web1.example.com"       # Standard output
  stdout_lines:                    # stdout as list
    - "web1.example.com"
  stderr: ""                       # Standard error
  stderr_lines: []                 # stderr as list
  failed: false                    # Did task fail?
  msg: ""                          # Error message if failed
```

### Practical Registration Examples

```yaml
---
- hosts: all
  tasks:
    # Example 1: Check if file exists
    - name: Check file
      stat:
        path: /etc/passwd
      register: passwd_stat

    - name: Show file info
      debug:
        msg: "File size: {{ passwd_stat.stat.size }} bytes"
      when: passwd_stat.stat.exists

    # Example 2: Command output processing
    - name: Get disk usage
      shell: "df -h / | tail -1 | awk '{print $5}'"
      register: disk_usage

    - name: Warn if disk full
      debug:
        msg: "WARNING: Disk usage at {{ disk_usage.stdout }}"
      when: disk_usage.stdout | replace('%','') | int > 80

    # Example 3: Loop registration
    - name: Check multiple services
      shell: "systemctl is-active {{ item }}"
      register: service_status
      loop:
        - sshd
        - nginx
      ignore_errors: yes

    - name: Show service statuses
      debug:
        msg: "{{ item.item }}: {{ item.stdout }}"
      loop: "{{ service_status.results }}"
```

---

## Practical Examples

### Example 1: Multi-Environment Configuration

```yaml
# group_vars/production.yml
---
env_name: production
debug_mode: false
log_level: warn
db_host: prod-db.example.com

# group_vars/staging.yml
---
env_name: staging
debug_mode: true
log_level: debug
db_host: staging-db.example.com

# playbook.yml
---
- hosts: all
  tasks:
    - name: Show environment
      debug:
        msg: |
          Environment: {{ env_name }}
          Debug: {{ debug_mode }}
          Database: {{ db_host }}
```

### Example 2: User Creation with Variables

```yaml
# vars/users.yml
---
users:
  - name: alice
    uid: 1001
    groups: [wheel, docker]
    shell: /bin/bash

  - name: bob
    uid: 1002
    groups: [developers]
    shell: /bin/zsh

# create-users.yml
---
- hosts: all
  vars_files:
    - vars/users.yml

  tasks:
    - name: Create users
      debug:
        msg: "Would create user {{ item.name }} (UID: {{ item.uid }})"
      loop: "{{ users }}"
```

### Example 3: Conditional Variables

```yaml
---
- hosts: all
  vars:
    # Default values
    http_port: 80
    ssl_enabled: false

  tasks:
    - name: Override for production
      set_fact:
        http_port: 443
        ssl_enabled: true
      when: "'production' in group_names"

    - name: Show configuration
      debug:
        msg: "Port: {{ http_port }}, SSL: {{ ssl_enabled }}"
```

### Example 4: Variable Validation

```yaml
---
- hosts: all
  vars:
    required_var: "{{ lookup('env', 'MY_VAR') | default('', true) }}"

  tasks:
    - name: Fail if variable not set
      fail:
        msg: "MY_VAR environment variable is required!"
      when: required_var == ''

    - name: Use the variable
      debug:
        msg: "MY_VAR = {{ required_var }}"
```

---

## Best Practices

### 1. Use Descriptive Variable Names

```yaml
# Good
http_server_port: 80
database_connection_timeout: 30
enable_ssl_verification: true

# Bad
port: 80
timeout: 30
flag: true
```

### 2. Organize Variables by Scope

```
project/
├── group_vars/
│   ├── all.yml           # Global defaults
│   ├── webservers.yml    # Web server settings
│   └── databases.yml     # Database settings
├── host_vars/
│   └── special-host.yml  # Host-specific overrides
└── vars/
    ├── secrets.yml       # Encrypted with ansible-vault
    └── packages.yml      # Package lists
```

### 3. Provide Defaults

```yaml
# In role defaults or playbook
http_port: "{{ custom_port | default(80) }}"
timeout: "{{ custom_timeout | default(30) }}"
```

### 4. Document Variables

```yaml
# vars/main.yml
---
# HTTP server configuration
# @var http_port: Port number for HTTP server (default: 80)
http_port: 80

# @var max_connections: Maximum concurrent connections
# Valid range: 100-10000
max_connections: 1000
```

### 5. Use Variable Files for Secrets

```bash
# Encrypt sensitive variables
ansible-vault encrypt vars/secrets.yml

# Use in playbook
ansible-playbook playbook.yml --ask-vault-pass
```

---

## Summary

In this section, you learned:

1. **Why variables matter**: Dynamic, reusable playbooks
2. **Variable types**: Strings, numbers, booleans, lists, dictionaries
3. **Defining variables**: group_vars, host_vars, play vars, extra vars
4. **Precedence**: Extra vars (-e) always win
5. **Special variables**: inventory_hostname, groups, hostvars
6. **Registered variables**: Capturing task output

---

## Next Steps

Continue to [Section 5: Facts](./SECTION_5.md) to learn about gathering system information automatically.

---

## Quick Reference

```yaml
# Variable definition locations
group_vars/all.yml        # All hosts
group_vars/webservers.yml # Group specific
host_vars/web1.yml        # Host specific
vars: in playbook         # Play level
-e "var=value"           # Command line (highest priority)

# Accessing variables
{{ simple_var }}
{{ list_var[0] }}
{{ dict_var.key }}
{{ dict_var['key'] }}
{{ var | default('fallback') }}

# Registration
register: result
{{ result.stdout }}
{{ result.rc }}
{{ result.failed }}
```
