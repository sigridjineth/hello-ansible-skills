# Section 7: Conditionals

## Table of Contents
- [Introduction to Conditionals](#introduction-to-conditionals)
- [The when Statement](#the-when-statement)
- [Comparison Operators](#comparison-operators)
- [Logical Operators](#logical-operators)
- [Testing Variables](#testing-variables)
- [Conditionals with Facts](#conditionals-with-facts)
- [Conditionals with Registered Variables](#conditionals-with-registered-variables)
- [Practical Examples](#practical-examples)

---

## Introduction to Conditionals

Conditionals let you **execute tasks selectively** based on conditions.

### Why Use Conditionals?

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONDITIONAL EXECUTION                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Task: Install Web Server                                       │
│                                                                  │
│         ┌──────────────────┐                                    │
│         │ What is the OS?  │                                    │
│         └────────┬─────────┘                                    │
│                  │                                               │
│     ┌────────────┼────────────┐                                 │
│     │            │            │                                 │
│     ▼            ▼            ▼                                 │
│  ┌──────┐   ┌──────┐    ┌──────┐                               │
│  │Debian│   │RedHat│    │Darwin│                               │
│  └──┬───┘   └──┬───┘    └──┬───┘                               │
│     │          │           │                                    │
│     ▼          ▼           ▼                                    │
│  apt install  yum install  brew install                        │
│    nginx        nginx        nginx                             │
│                                                                  │
│  Same goal, different methods based on condition!              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## The when Statement

### Basic Syntax

```yaml
---
- hosts: all
  tasks:
    - name: This task runs conditionally
      debug:
        msg: "Condition is true!"
      when: some_condition
```

### Key Points About when

1. **No Jinja2 braces** - `when` is evaluated as Jinja2 automatically
2. **Raw expressions** - Write conditions directly
3. **Boolean result** - Must evaluate to true/false

```yaml
# CORRECT - No braces needed
when: my_var == "value"
when: ansible_facts['os_family'] == "Debian"

# INCORRECT - Don't use braces
when: "{{ my_var }}" == "value"  # WRONG!
```

---

## Comparison Operators

### Standard Comparisons

| Operator | Description | Example |
|----------|-------------|---------|
| `==` | Equal to | `when: x == 5` |
| `!=` | Not equal to | `when: x != 5` |
| `>` | Greater than | `when: x > 5` |
| `<` | Less than | `when: x < 5` |
| `>=` | Greater than or equal | `when: x >= 5` |
| `<=` | Less than or equal | `when: x <= 5` |

### Examples

```yaml
---
- hosts: all
  vars:
    http_port: 80
    max_clients: 200
    environment: production

  tasks:
    - name: Check port number
      debug:
        msg: "Using standard HTTP port"
      when: http_port == 80

    - name: Check high traffic setting
      debug:
        msg: "High traffic configuration"
      when: max_clients > 100

    - name: Check environment
      debug:
        msg: "Running in production"
      when: environment == "production"

    - name: Check non-standard port
      debug:
        msg: "Using non-standard port {{ http_port }}"
      when: http_port != 80
```

---

## Logical Operators

### Combining Conditions

| Operator | Description | Example |
|----------|-------------|---------|
| `and` | Both must be true | `when: a and b` |
| `or` | Either can be true | `when: a or b` |
| `not` | Negation | `when: not a` |
| `()` | Grouping | `when: (a or b) and c` |

### Examples

```yaml
---
- hosts: all
  vars:
    is_production: true
    memory_mb: 8192
    cpu_cores: 4

  tasks:
    # AND condition
    - name: High-performance production server
      debug:
        msg: "This is a powerful production server"
      when: is_production and memory_mb >= 8192

    # OR condition
    - name: Needs attention
      debug:
        msg: "Server needs resource upgrade"
      when: memory_mb < 4096 or cpu_cores < 2

    # NOT condition
    - name: Not production
      debug:
        msg: "This is NOT production"
      when: not is_production

    # Complex condition with grouping
    - name: Specific configuration needed
      debug:
        msg: "Apply special configuration"
      when: (is_production and memory_mb >= 8192) or cpu_cores >= 8

    # Multiple conditions (implicit AND)
    - name: Multiple conditions
      debug:
        msg: "All conditions met"
      when:
        - is_production
        - memory_mb >= 4096
        - cpu_cores >= 2
      # Equivalent to: when: is_production and memory_mb >= 4096 and cpu_cores >= 2
```

---

## Testing Variables

### Common Tests

| Test | Description | Example |
|------|-------------|---------|
| `defined` | Variable exists | `when: my_var is defined` |
| `undefined` | Variable doesn't exist | `when: my_var is undefined` |
| `none` | Variable is None/null | `when: my_var is none` |
| `true` / `false` | Boolean check | `when: my_var is true` |
| `string` | Is a string | `when: my_var is string` |
| `number` | Is a number | `when: my_var is number` |
| `iterable` | Is a list/dict | `when: my_var is iterable` |

### Variable Existence

```yaml
---
- hosts: all
  vars:
    defined_var: "I exist"
    # undefined_var is not defined

  tasks:
    - name: Run if variable is defined
      debug:
        msg: "Variable exists: {{ defined_var }}"
      when: defined_var is defined

    - name: Run if variable is NOT defined
      debug:
        msg: "Using default value"
      when: undefined_var is undefined

    - name: Safe variable access with default
      debug:
        msg: "Value: {{ optional_var | default('fallback') }}"
```

### String Tests

| Test | Description | Example |
|------|-------------|---------|
| `match` | Regex match (start) | `when: x is match("^web")` |
| `search` | Regex search (anywhere) | `when: x is search("error")` |
| `in` | String contains | `when: "web" in hostname` |

```yaml
---
- hosts: all
  vars:
    server_name: "web-prod-01"

  tasks:
    - name: Check if web server
      debug:
        msg: "This is a web server"
      when: server_name is match("^web")

    - name: Check if production
      debug:
        msg: "This is production"
      when: "'prod' in server_name"

    - name: Check using search
      debug:
        msg: "Found production indicator"
      when: server_name is search("prod")
```

### List Tests

```yaml
---
- hosts: all
  vars:
    my_list:
      - apple
      - banana
      - cherry
    empty_list: []

  tasks:
    - name: Check if item in list
      debug:
        msg: "Apple is in the list"
      when: "'apple' in my_list"

    - name: Check if list is not empty
      debug:
        msg: "List has items"
      when: my_list | length > 0

    - name: Check empty list
      debug:
        msg: "List is empty"
      when: empty_list | length == 0
```

---

## Conditionals with Facts

### OS-Based Conditions

```yaml
---
- hosts: all
  tasks:
    # Check OS family
    - name: Debian-based systems
      debug:
        msg: "This is a Debian-based system"
      when: ansible_facts['os_family'] == "Debian"

    - name: RedHat-based systems
      debug:
        msg: "This is a RedHat-based system"
      when: ansible_facts['os_family'] == "RedHat"

    - name: macOS systems
      debug:
        msg: "This is macOS"
      when: ansible_facts['os_family'] == "Darwin"

    # Check specific distribution
    - name: Ubuntu only
      debug:
        msg: "Running on Ubuntu"
      when:
        - ansible_facts['distribution'] == "Ubuntu"
        - ansible_facts['distribution_major_version'] | int >= 20
```

### Supported OS Check Example

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
    - name: Print supported OS message
      debug:
        msg: "This {{ ansible_facts['os_family'] }} system is supported!"
      when: ansible_facts['os_family'] in supported_os

    - name: Print unsupported OS message
      debug:
        msg: "This {{ ansible_facts['os_family'] }} system is NOT in the supported list!"
      when: ansible_facts['os_family'] not in supported_os
```

### Resource-Based Conditions

```yaml
---
- hosts: all
  tasks:
    - name: Configure for high memory
      debug:
        msg: "Enabling high-memory configuration"
      when: ansible_facts['memtotal_mb'] >= 8192

    - name: Configure for low memory
      debug:
        msg: "Enabling low-memory configuration"
      when: ansible_facts['memtotal_mb'] < 4096

    - name: Multi-core optimizations
      debug:
        msg: "Enabling multi-core optimizations"
      when: ansible_facts['processor_cores'] | default(1) >= 4
```

---

## Conditionals with Registered Variables

### Check Task Results

```yaml
---
- hosts: all
  tasks:
    - name: Check if file exists
      stat:
        path: /tmp/important.conf
      register: config_file

    - name: Create config if missing
      debug:
        msg: "Would create config file"
      when: not config_file.stat.exists

    - name: Use existing config
      debug:
        msg: "Config file exists, size: {{ config_file.stat.size }} bytes"
      when: config_file.stat.exists
```

### Check Command Results

```yaml
# when-task.yml / when-task-false.yml
---
- hosts: all
  vars:
    run_my_task: false    # Change to true to see different behavior

  tasks:
    - name: Conditionally run task
      shell: "echo 'Task executed!'"
      when: run_my_task
      register: result

    - name: Show result (skipped variable info)
      debug:
        var: result

# When run_my_task is false:
# result will have 'skipped': true
```

### Check for Failures

```yaml
---
- hosts: all
  tasks:
    - name: Try to run command
      shell: "ls /nonexistent"
      register: cmd_result
      ignore_errors: yes

    - name: Handle failure
      debug:
        msg: "Command failed: {{ cmd_result.stderr }}"
      when: cmd_result.failed

    - name: Handle success
      debug:
        msg: "Command succeeded"
      when: not cmd_result.failed

    # Alternative using rc (return code)
    - name: Check return code
      debug:
        msg: "Command exited with code {{ cmd_result.rc }}"
      when: cmd_result.rc != 0
```

### Check Changed Status

```yaml
---
- hosts: all
  tasks:
    - name: Create file
      file:
        path: /tmp/test.txt
        state: touch
      register: file_result

    - name: Notify if changed
      debug:
        msg: "File was created or modified!"
      when: file_result.changed

    - name: Already exists
      debug:
        msg: "File already existed"
      when: not file_result.changed
```

---

## Practical Examples

### Example 1: Environment-Based Configuration

```yaml
---
- hosts: all
  vars:
    env: production  # Can be: development, staging, production

  tasks:
    - name: Development settings
      debug:
        msg: |
          Debug: enabled
          Log level: debug
          Workers: 1
      when: env == "development"

    - name: Staging settings
      debug:
        msg: |
          Debug: enabled
          Log level: info
          Workers: 2
      when: env == "staging"

    - name: Production settings
      debug:
        msg: |
          Debug: disabled
          Log level: warn
          Workers: auto
      when: env == "production"
```

### Example 2: Package Installation by OS

```yaml
---
- hosts: all
  tasks:
    - name: Install on Debian/Ubuntu (apt)
      debug:
        msg: "apt-get install nginx"
      when: ansible_facts['os_family'] == "Debian"

    - name: Install on RedHat/CentOS (yum/dnf)
      debug:
        msg: "yum install nginx"
      when: ansible_facts['os_family'] == "RedHat"

    - name: Install on macOS (brew)
      debug:
        msg: "brew install nginx"
      when: ansible_facts['os_family'] == "Darwin"

    - name: Unsupported OS
      fail:
        msg: "OS family {{ ansible_facts['os_family'] }} is not supported"
      when: ansible_facts['os_family'] not in ['Debian', 'RedHat', 'Darwin']
```

### Example 3: Service State Management

```yaml
---
- hosts: all
  vars:
    manage_nginx: true
    nginx_state: started  # started, stopped, restarted

  tasks:
    - name: Start nginx
      debug:
        msg: "Starting nginx service"
      when:
        - manage_nginx
        - nginx_state == "started"

    - name: Stop nginx
      debug:
        msg: "Stopping nginx service"
      when:
        - manage_nginx
        - nginx_state == "stopped"

    - name: Restart nginx
      debug:
        msg: "Restarting nginx service"
      when:
        - manage_nginx
        - nginx_state == "restarted"
```

### Example 4: Conditional File Operations

```yaml
---
- hosts: all
  tasks:
    - name: Check if backup exists
      stat:
        path: /tmp/backup.tar.gz
      register: backup

    - name: Skip if backup exists
      debug:
        msg: "Backup already exists, skipping..."
      when: backup.stat.exists

    - name: Create backup
      debug:
        msg: "Creating new backup..."
      when: not backup.stat.exists

    - name: Check backup age
      debug:
        msg: "Backup is old, consider refreshing"
      when:
        - backup.stat.exists
        - (ansible_facts['date_time']['epoch'] | int) - (backup.stat.mtime | int) > 86400
```

### Example 5: Complex Multi-Condition Logic

```yaml
---
- hosts: all
  vars:
    is_production: true
    maintenance_mode: false
    deploy_version: "2.0.0"
    current_version: "1.9.0"

  tasks:
    - name: Check deployment conditions
      debug:
        msg: "Ready to deploy {{ deploy_version }}"
      when:
        - not maintenance_mode
        - deploy_version != current_version
        - is_production or "'staging' in group_names"

    - name: Block deployment during maintenance
      debug:
        msg: "Deployment blocked - maintenance mode active"
      when: maintenance_mode

    - name: No deployment needed
      debug:
        msg: "Already running version {{ deploy_version }}"
      when: deploy_version == current_version
```

---

## Summary

In this section, you learned:

1. **when statement**: Basic conditional syntax
2. **Comparison operators**: `==`, `!=`, `>`, `<`, `>=`, `<=`
3. **Logical operators**: `and`, `or`, `not`, grouping with `()`
4. **Testing variables**: `defined`, `undefined`, `in`, `match`, `search`
5. **Facts in conditions**: OS-based, resource-based decisions
6. **Registered variables**: Check task results, failures, changes

---

## Next Steps

Continue to [Section 8: Handlers](./SECTION_8.md) to learn about triggered tasks.

---

## Quick Reference

```yaml
# Basic when
when: my_var == "value"

# Multiple conditions (AND)
when:
  - condition1
  - condition2

# OR conditions
when: condition1 or condition2

# NOT
when: not my_var

# Variable tests
when: my_var is defined
when: my_var is undefined
when: "'item' in my_list"

# Fact conditions
when: ansible_facts['os_family'] == "Debian"
when: ansible_facts['memtotal_mb'] >= 8192

# Registered variable conditions
when: result.failed
when: result.changed
when: result.rc == 0
when: result.stat.exists
```
