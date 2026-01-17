# Section 5: Ansible Facts

## Table of Contents
- [What are Facts?](#what-are-facts)
- [Gathering Facts](#gathering-facts)
- [Common Facts](#common-facts)
- [Using Facts in Playbooks](#using-facts-in-playbooks)
- [Custom Facts](#custom-facts)
- [Caching Facts](#caching-facts)
- [Practical Examples](#practical-examples)

---

## What are Facts?

**Facts** are system information that Ansible automatically collects from managed nodes.

### Facts Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      ANSIBLE FACTS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Control Node                      Managed Node                 │
│  ┌──────────────┐                  ┌──────────────────────┐    │
│  │              │   1. Connect     │                      │    │
│  │   Ansible    │ ───────────────► │     Target Server    │    │
│  │              │                  │                      │    │
│  │              │   2. Run setup   │  ┌────────────────┐  │    │
│  │              │ ───────────────► │  │ setup module   │  │    │
│  │              │                  │  └───────┬────────┘  │    │
│  │              │                  │          │           │    │
│  │              │   3. Return      │  Collect info:      │    │
│  │  ┌────────┐  │ ◄─────────────── │  • OS type         │    │
│  │  │ Facts  │  │                  │  • IP addresses    │    │
│  │  │ Dict   │  │                  │  • Memory          │    │
│  │  └────────┘  │                  │  • CPU             │    │
│  │              │                  │  • Disks           │    │
│  └──────────────┘                  │  • Users           │    │
│                                    │  • Network         │    │
│                                    └──────────────────────┘    │
│                                                                  │
│  Facts are available as {{ ansible_facts['key'] }}              │
│  or the legacy {{ ansible_key }} format                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why Facts Matter

| Use Case | Example |
|----------|---------|
| **Conditional execution** | Install packages based on OS |
| **Dynamic configuration** | Set memory limits based on RAM |
| **Templating** | Generate configs with actual IPs |
| **Reporting** | Inventory system information |

---

## Gathering Facts

### Automatic Gathering (Default)

By default, Ansible runs the `setup` module at the start of every play:

```yaml
---
- hosts: all
  # gather_facts: yes   # This is the default

  tasks:
    - name: Show OS
      debug:
        msg: "OS: {{ ansible_facts['distribution'] }}"
```

### Manual Gathering

You can disable automatic gathering and collect manually:

```yaml
---
- hosts: all
  gather_facts: no       # Disable automatic gathering

  tasks:
    - name: Do something without facts
      debug:
        msg: "No facts needed here"

    - name: Now gather facts
      setup:              # Manually run setup module

    - name: Use facts
      debug:
        msg: "OS: {{ ansible_facts['distribution'] }}"
```

### Viewing All Facts

```bash
# Ad-hoc command to see all facts
$ ansible localhost -m setup

localhost | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": ["192.168.1.100"],
        "ansible_architecture": "arm64",
        "ansible_date_time": {
            "date": "2024-01-15",
            "time": "10:30:45"
        },
        "ansible_distribution": "MacOSX",
        "ansible_hostname": "MacBook-Pro",
        "ansible_memtotal_mb": 16384,
        ...
    }
}

# Filter specific facts
$ ansible localhost -m setup -a "filter=ansible_distribution*"

$ ansible localhost -m setup -a "filter=ansible_memory*"
```

---

## Common Facts

### System Facts

| Fact | Description | Example Value |
|------|-------------|---------------|
| `ansible_facts['hostname']` | Short hostname | `web1` |
| `ansible_facts['fqdn']` | Fully qualified domain name | `web1.example.com` |
| `ansible_facts['distribution']` | OS distribution | `Ubuntu`, `CentOS`, `MacOSX` |
| `ansible_facts['distribution_version']` | OS version | `22.04`, `8.5` |
| `ansible_facts['os_family']` | OS family | `Debian`, `RedHat`, `Darwin` |
| `ansible_facts['architecture']` | CPU architecture | `x86_64`, `arm64` |
| `ansible_facts['kernel']` | Kernel version | `5.15.0-60-generic` |

### Hardware Facts

| Fact | Description | Example Value |
|------|-------------|---------------|
| `ansible_facts['processor']` | CPU info | List of CPU details |
| `ansible_facts['processor_count']` | Number of CPUs | `4` |
| `ansible_facts['processor_cores']` | Cores per CPU | `8` |
| `ansible_facts['memtotal_mb']` | Total RAM (MB) | `16384` |
| `ansible_facts['memfree_mb']` | Free RAM (MB) | `8192` |
| `ansible_facts['swaptotal_mb']` | Total swap (MB) | `4096` |

### Network Facts

| Fact | Description | Example Value |
|------|-------------|---------------|
| `ansible_facts['default_ipv4']` | Default IPv4 info | Dict with address, gateway |
| `ansible_facts['all_ipv4_addresses']` | All IPv4 addresses | List of IPs |
| `ansible_facts['interfaces']` | Network interfaces | `['eth0', 'lo']` |
| `ansible_facts['eth0']` | Specific interface | Dict with IP, MAC, etc. |

### Storage Facts

| Fact | Description | Example Value |
|------|-------------|---------------|
| `ansible_facts['devices']` | Block devices | Dict of devices |
| `ansible_facts['mounts']` | Mounted filesystems | List of mount info |

### Date/Time Facts

```yaml
ansible_facts['date_time']:
  date: "2024-01-15"
  day: "15"
  epoch: "1705312245"
  hour: "10"
  iso8601: "2024-01-15T10:30:45Z"
  minute: "30"
  month: "01"
  second: "45"
  time: "10:30:45"
  tz: "UTC"
  weekday: "Monday"
  year: "2024"
```

---

## Using Facts in Playbooks

### Basic Fact Usage

```yaml
---
- hosts: all
  tasks:
    - name: Display system information
      debug:
        msg: |
          Hostname: {{ ansible_facts['hostname'] }}
          OS: {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}
          Architecture: {{ ansible_facts['architecture'] }}
          Memory: {{ ansible_facts['memtotal_mb'] }} MB
          IP: {{ ansible_facts['default_ipv4']['address'] | default('N/A') }}
```

### Conditional Execution Based on Facts

```yaml
---
- hosts: all
  tasks:
    # Install packages based on OS family
    - name: Install on Debian/Ubuntu
      apt:
        name: nginx
        state: present
      when: ansible_facts['os_family'] == "Debian"

    - name: Install on RedHat/CentOS
      yum:
        name: nginx
        state: present
      when: ansible_facts['os_family'] == "RedHat"

    - name: Install on macOS
      homebrew:
        name: nginx
        state: present
      when: ansible_facts['os_family'] == "Darwin"
```

### Facts in Templates

```jinja2
{# nginx.conf.j2 #}
# Generated by Ansible for {{ ansible_facts['hostname'] }}
# OS: {{ ansible_facts['distribution'] }}

worker_processes {{ ansible_facts['processor_cores'] }};

events {
    worker_connections {{ (ansible_facts['memtotal_mb'] / 4) | int }};
}

http {
    server {
        listen 80;
        server_name {{ ansible_facts['fqdn'] }};

        location / {
            root /var/www/html;
        }
    }
}
```

### Memory-Based Configuration

```yaml
---
- hosts: all
  tasks:
    - name: Calculate JVM heap size (50% of RAM)
      set_fact:
        jvm_heap_mb: "{{ (ansible_facts['memtotal_mb'] * 0.5) | int }}"

    - name: Show JVM configuration
      debug:
        msg: "JVM Heap: {{ jvm_heap_mb }} MB (Total RAM: {{ ansible_facts['memtotal_mb'] }} MB)"
```

---

## Custom Facts

You can define your own facts on managed nodes.

### Local Facts (fact.d)

Create files in `/etc/ansible/facts.d/` on managed nodes:

```bash
# On managed node: /etc/ansible/facts.d/custom.fact
[application]
name = MyApp
version = 2.0.1
environment = production

[database]
host = db.example.com
port = 5432
```

Access in playbooks:
```yaml
- name: Show custom facts
  debug:
    msg: |
      App: {{ ansible_facts['ansible_local']['custom']['application']['name'] }}
      Version: {{ ansible_facts['ansible_local']['custom']['application']['version'] }}
```

### Executable Facts

```bash
#!/bin/bash
# /etc/ansible/facts.d/dynamic.fact (must be executable)

# Output must be valid JSON
cat << EOF
{
    "app_version": "$(cat /opt/app/VERSION 2>/dev/null || echo 'unknown')",
    "uptime_seconds": $(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1),
    "load_average": "$(uptime | awk -F'load average:' '{print $2}' | xargs)"
}
EOF
```

### set_fact Module

Create facts dynamically during playbook execution:

```yaml
---
- hosts: all
  tasks:
    - name: Set custom fact
      set_fact:
        my_custom_var: "calculated_value"
        deployment_time: "{{ ansible_facts['date_time']['iso8601'] }}"

    - name: Use custom fact
      debug:
        msg: "Custom: {{ my_custom_var }}, Deployed: {{ deployment_time }}"
```

---

## Caching Facts

For large infrastructures, caching facts improves performance.

### Enable Fact Caching (ansible.cfg)

```ini
# ansible.cfg
[defaults]
gathering = smart            # Only gather when needed
fact_caching = jsonfile      # Cache backend
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 86400  # Cache for 24 hours (seconds)
```

### Caching Backends

| Backend | Description | Configuration |
|---------|-------------|---------------|
| `memory` | In-memory (current run only) | Default |
| `jsonfile` | JSON files on disk | `fact_caching_connection = /path/to/dir` |
| `redis` | Redis server | `fact_caching_connection = localhost:6379:0` |
| `memcached` | Memcached server | `fact_caching_connection = localhost:11211` |

### Gathering Strategies

```ini
[defaults]
# Gathering options:
# - implicit: Always gather (default)
# - explicit: Only when gather_facts: yes
# - smart: Only if not cached

gathering = smart
```

---

## Practical Examples

### Example 1: System Information Report

```yaml
# facts.yml
---
- hosts: all
  tasks:
    - name: Generate system report
      debug:
        msg: |
          ═══════════════════════════════════════
          SYSTEM INFORMATION REPORT
          ═══════════════════════════════════════

          BASIC INFO
          ──────────
          Hostname:     {{ ansible_facts['hostname'] }}
          FQDN:         {{ ansible_facts['fqdn'] }}
          OS:           {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}
          OS Family:    {{ ansible_facts['os_family'] }}
          Architecture: {{ ansible_facts['architecture'] }}
          Kernel:       {{ ansible_facts['kernel'] }}

          HARDWARE
          ────────
          CPUs:         {{ ansible_facts['processor_count'] }}
          Cores:        {{ ansible_facts['processor_cores'] | default('N/A') }}
          Memory:       {{ ansible_facts['memtotal_mb'] }} MB
          Free Memory:  {{ ansible_facts['memfree_mb'] | default('N/A') }} MB

          NETWORK
          ───────
          IP Address:   {{ ansible_facts['default_ipv4']['address'] | default('N/A') }}
          Gateway:      {{ ansible_facts['default_ipv4']['gateway'] | default('N/A') }}
          Interfaces:   {{ ansible_facts['interfaces'] | join(', ') }}

          TIME
          ────
          Date:         {{ ansible_facts['date_time']['date'] }}
          Time:         {{ ansible_facts['date_time']['time'] }}
          Timezone:     {{ ansible_facts['date_time']['tz'] }}

          ═══════════════════════════════════════
```

### Example 2: OS-Agnostic Package Installation

```yaml
---
- hosts: all
  vars:
    packages_debian:
      - nginx
      - vim
      - git
    packages_redhat:
      - nginx
      - vim
      - git
    packages_darwin:
      - nginx
      - vim
      - git

  tasks:
    - name: Set package list based on OS
      set_fact:
        packages: "{{ vars['packages_' + ansible_facts['os_family'] | lower] | default([]) }}"

    - name: Show packages to install
      debug:
        msg: "Would install on {{ ansible_facts['os_family'] }}: {{ packages }}"
```

### Example 3: Memory-Based Application Tuning

```yaml
---
- hosts: all
  tasks:
    - name: Calculate application memory settings
      set_fact:
        # Reserve 20% for OS, use 80% for app
        app_memory_mb: "{{ (ansible_facts['memtotal_mb'] * 0.8) | int }}"
        # JVM heap: 50% of app memory
        jvm_heap_mb: "{{ (ansible_facts['memtotal_mb'] * 0.4) | int }}"
        # Worker processes: one per core
        worker_count: "{{ ansible_facts['processor_cores'] | default(2) }}"

    - name: Display tuning parameters
      debug:
        msg: |
          Total Memory: {{ ansible_facts['memtotal_mb'] }} MB
          App Memory:   {{ app_memory_mb }} MB
          JVM Heap:     {{ jvm_heap_mb }} MB
          Workers:      {{ worker_count }}
```

### Example 4: Supported OS Check

```yaml
# check-os.yml
---
- hosts: all
  vars:
    supported_os:
      - Darwin
      - Debian
      - RedHat

  tasks:
    - name: Check if OS is supported
      debug:
        msg: "{{ ansible_facts['os_family'] }} is SUPPORTED!"
      when: ansible_facts['os_family'] in supported_os

    - name: Warn about unsupported OS
      debug:
        msg: "WARNING: {{ ansible_facts['os_family'] }} is NOT supported!"
      when: ansible_facts['os_family'] not in supported_os

    - name: Fail on unsupported OS (optional)
      fail:
        msg: "Cannot continue: {{ ansible_facts['os_family'] }} is not supported"
      when:
        - ansible_facts['os_family'] not in supported_os
        - strict_os_check | default(false)
```

---

## Summary

In this section, you learned:

1. **What facts are**: Automatic system information collection
2. **Gathering facts**: Automatic vs manual, filtering
3. **Common facts**: System, hardware, network, storage, time
4. **Using facts**: Conditionals, templates, calculations
5. **Custom facts**: Local facts, executable facts, set_fact
6. **Caching**: Improve performance for large infrastructures

---

## Next Steps

Continue to [Section 6: Loops](./SECTION_6.md) to learn how to iterate over lists and dictionaries.

---

## Quick Reference

```bash
# View all facts
ansible localhost -m setup

# Filter facts
ansible localhost -m setup -a "filter=ansible_distribution*"
ansible localhost -m setup -a "filter=ansible_memory*"
ansible localhost -m setup -a "filter=*ipv4*"
```

```yaml
# Common fact access patterns
{{ ansible_facts['hostname'] }}
{{ ansible_facts['distribution'] }}
{{ ansible_facts['os_family'] }}
{{ ansible_facts['memtotal_mb'] }}
{{ ansible_facts['processor_cores'] }}
{{ ansible_facts['default_ipv4']['address'] }}
{{ ansible_facts['date_time']['iso8601'] }}

# Disable fact gathering
gather_facts: no

# Manual fact gathering
- setup:
    filter: "ansible_memory*"
```
