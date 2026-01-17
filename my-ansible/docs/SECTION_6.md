# Section 6: Loops

## Table of Contents
- [Introduction to Loops](#introduction-to-loops)
- [Simple Loops](#simple-loops)
- [Loop with Index](#loop-with-index)
- [Dictionary Loops](#dictionary-loops)
- [Nested Loops](#nested-loops)
- [Loop Control](#loop-control)
- [Registering Loop Output](#registering-loop-output)
- [Practical Examples](#practical-examples)

---

## Introduction to Loops

Loops allow you to **repeat tasks** without writing duplicate code.

### Why Use Loops?

```
┌─────────────────────────────────────────────────────────────────┐
│                    WITHOUT LOOPS (BAD)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  tasks:                                                         │
│    - name: Install nginx                                        │
│      apt: name=nginx state=present                              │
│                                                                  │
│    - name: Install vim                                          │
│      apt: name=vim state=present         ← REPETITIVE!         │
│                                                                  │
│    - name: Install git                                          │
│      apt: name=git state=present                                │
│                                                                  │
│    - name: Install curl                                         │
│      apt: name=curl state=present                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      WITH LOOPS (GOOD)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  tasks:                                                         │
│    - name: Install packages                                     │
│      apt:                                                       │
│        name: "{{ item }}"           ← SINGLE TASK              │
│        state: present                                           │
│      loop:                                                      │
│        - nginx                                                  │
│        - vim                                                    │
│        - git                                                    │
│        - curl                                                   │
│                                                                  │
│  One task, multiple items!                                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Loop Keywords

| Keyword | Description | Use Case |
|---------|-------------|----------|
| `loop` | Modern, recommended | Most looping needs |
| `with_items` | Legacy (still works) | Simple lists |
| `with_dict` | Legacy | Dictionaries |
| `with_fileglob` | Legacy | File patterns |
| `with_sequence` | Legacy | Number sequences |

**Recommendation**: Use `loop` for new playbooks.

---

## Simple Loops

### Basic List Loop

```yaml
---
- hosts: all
  tasks:
    - name: Create multiple files
      file:
        path: "/tmp/{{ item }}"
        state: touch
      loop:
        - file1.txt
        - file2.txt
        - file3.txt

# Output:
# TASK [Create multiple files] *******************
# changed: [localhost] => (item=file1.txt)
# changed: [localhost] => (item=file2.txt)
# changed: [localhost] => (item=file3.txt)
```

### Loop with Variable

```yaml
---
- hosts: all
  vars:
    packages:
      - nginx
      - vim
      - git
      - curl

  tasks:
    - name: Install packages
      debug:
        msg: "Would install {{ item }}"
      loop: "{{ packages }}"
```

### Loop with Range

```yaml
---
- hosts: all
  tasks:
    # Create files numbered 1-5
    - name: Create numbered files
      file:
        path: "/tmp/file{{ item }}.txt"
        state: touch
      loop: "{{ range(1, 6) | list }}"
      # Creates: file1.txt, file2.txt, file3.txt, file4.txt, file5.txt

    # Alternative with sequence
    - name: Create with sequence
      debug:
        msg: "Number {{ item }}"
      loop: "{{ range(0, 10, 2) | list }}"
      # Output: 0, 2, 4, 6, 8 (step by 2)
```

---

## Loop with Index

### Using loop_control.index_var

```yaml
---
- hosts: all
  tasks:
    - name: Show items with index
      debug:
        msg: "Index {{ my_idx }}: {{ item }}"
      loop:
        - apple
        - banana
        - cherry
      loop_control:
        index_var: my_idx

# Output:
# "Index 0: apple"
# "Index 1: banana"
# "Index 2: cherry"
```

### Using extended Loop Variables

```yaml
---
- hosts: all
  tasks:
    - name: Extended loop info
      debug:
        msg: |
          Item: {{ item }}
          Index: {{ ansible_loop.index }} (1-based)
          Index0: {{ ansible_loop.index0 }} (0-based)
          First: {{ ansible_loop.first }}
          Last: {{ ansible_loop.last }}
          Length: {{ ansible_loop.length }}
      loop:
        - one
        - two
        - three
      loop_control:
        extended: yes

# First iteration:
# Item: one, Index: 1, Index0: 0, First: true, Last: false, Length: 3
```

---

## Dictionary Loops

### Loop Over Dictionary

```yaml
---
- hosts: all
  vars:
    users:
      alice:
        uid: 1001
        groups: wheel
      bob:
        uid: 1002
        groups: developers

  tasks:
    - name: Show user info
      debug:
        msg: "User {{ item.key }}: UID={{ item.value.uid }}, Groups={{ item.value.groups }}"
      loop: "{{ users | dict2items }}"

# Output:
# "User alice: UID=1001, Groups=wheel"
# "User bob: UID=1002, Groups=developers"
```

### Loop Over List of Dictionaries

```yaml
---
- hosts: all
  vars:
    files:
      - path: /tmp/config.yml
        mode: '0644'
        content: "setting: value"
      - path: /tmp/script.sh
        mode: '0755'
        content: "#!/bin/bash\necho hello"

  tasks:
    - name: Create files with different permissions
      copy:
        dest: "{{ item.path }}"
        content: "{{ item.content }}"
        mode: "{{ item.mode }}"
      loop: "{{ files }}"
```

### Practical Dictionary Example

```yaml
# make-file.yml
---
- hosts: all
  vars:
    file_list:
      - name: dev.yml
        path: /tmp/dev
      - name: stg.yml
        path: /tmp/stg
      - name: prd.yml
        path: /tmp/prd

  tasks:
    - name: Create directories
      file:
        path: "{{ item.path }}"
        state: directory
        mode: '0755'
      loop: "{{ file_list }}"

    - name: Create config files
      copy:
        dest: "{{ item.path }}/{{ item.name }}"
        content: |
          # Configuration for {{ item.name }}
          environment: {{ item.name | replace('.yml', '') }}
        mode: '0644'
      loop: "{{ file_list }}"

    - name: Show created files
      shell: "find /tmp -name '*.yml' -path '/tmp/*'"
      register: result

    - name: Display results
      debug:
        var: result.stdout_lines
```

---

## Nested Loops

### Using loop with subelements

```yaml
---
- hosts: all
  vars:
    users:
      - name: alice
        groups:
          - wheel
          - docker
      - name: bob
        groups:
          - developers

  tasks:
    - name: Show user-group combinations
      debug:
        msg: "User {{ item.0.name }} in group {{ item.1 }}"
      loop: "{{ users | subelements('groups') }}"

# Output:
# "User alice in group wheel"
# "User alice in group docker"
# "User bob in group developers"
```

### Using product Filter (Cartesian Product)

```yaml
---
- hosts: all
  vars:
    environments:
      - dev
      - staging
      - prod
    services:
      - web
      - api
      - worker

  tasks:
    - name: Show all environment-service combinations
      debug:
        msg: "{{ item.0 }}-{{ item.1 }}"
      loop: "{{ environments | product(services) | list }}"

# Output:
# "dev-web", "dev-api", "dev-worker"
# "staging-web", "staging-api", "staging-worker"
# "prod-web", "prod-api", "prod-worker"
```

---

## Loop Control

### Controlling Loop Behavior

```yaml
---
- hosts: all
  tasks:
    - name: Loop with control options
      debug:
        msg: "Processing {{ my_item }}"
      loop:
        - item1
        - item2
        - item3
      loop_control:
        loop_var: my_item        # Change default 'item' variable name
        index_var: my_idx        # Add index variable
        label: "{{ my_item }}"   # Customize output label
        pause: 1                 # Pause 1 second between items
        extended: yes            # Enable extended loop info
```

### Custom Loop Variable Names

Useful when nesting loops or including tasks:

```yaml
---
- hosts: all
  tasks:
    - name: Outer loop
      debug:
        msg: "Outer: {{ outer_item }}"
      loop:
        - A
        - B
      loop_control:
        loop_var: outer_item

    # In included tasks, 'item' would conflict without custom names
```

### Clean Output with label

```yaml
---
- hosts: all
  vars:
    users:
      - name: alice
        password: secret123
        email: alice@example.com
      - name: bob
        password: secret456
        email: bob@example.com

  tasks:
    - name: Process users (hide sensitive data)
      debug:
        msg: "Processing user {{ item.name }}"
      loop: "{{ users }}"
      loop_control:
        label: "{{ item.name }}"  # Only show name, not password!

# Without label: (item={'name': 'alice', 'password': 'secret123', ...})
# With label: (item=alice)
```

---

## Registering Loop Output

### Capture Loop Results

```yaml
---
- hosts: all
  tasks:
    - name: Check multiple files
      stat:
        path: "{{ item }}"
      loop:
        - /etc/passwd
        - /etc/shadow
        - /etc/nonexistent
      register: file_checks

    - name: Show all results
      debug:
        var: file_checks

    - name: Show individual results
      debug:
        msg: "{{ item.item }}: exists={{ item.stat.exists }}"
      loop: "{{ file_checks.results }}"
```

### Structure of Registered Loop Results

```yaml
file_checks:
  changed: false
  msg: "All items completed"
  results:                        # List of results, one per iteration
    - item: "/etc/passwd"         # The loop item
      stat:
        exists: true
        size: 2847
      changed: false
      failed: false

    - item: "/etc/shadow"
      stat:
        exists: true
      changed: false
      failed: false

    - item: "/etc/nonexistent"
      stat:
        exists: false
      changed: false
      failed: false
```

### Using Registered Results in Conditions

```yaml
---
- hosts: all
  tasks:
    - name: Try to connect to services
      uri:
        url: "{{ item }}"
        method: GET
        status_code: [200, 301, 302]
      loop:
        - http://google.com
        - http://localhost:9999
      register: url_checks
      ignore_errors: yes

    - name: Report failed connections
      debug:
        msg: "FAILED: {{ item.item }}"
      loop: "{{ url_checks.results }}"
      when: item.failed
```

---

## Practical Examples

### Example 1: Create Multiple Users

```yaml
# loop-example.yml
---
- hosts: all
  vars:
    users:
      - name: ansible1
        comment: "Ansible User 1"
      - name: ansible2
        comment: "Ansible User 2"
      - name: ansible3
        comment: "Ansible User 3"

  tasks:
    - name: Display user creation info
      debug:
        msg: "Would create user: {{ item.name }} ({{ item.comment }})"
      loop: "{{ users }}"
```

### Example 2: Install Multiple Packages

```yaml
---
- hosts: all
  vars:
    base_packages:
      - vim
      - git
      - curl
      - wget

    dev_packages:
      - nodejs
      - python3-pip

  tasks:
    - name: Show base packages
      debug:
        msg: "Base package: {{ item }}"
      loop: "{{ base_packages }}"

    - name: Show dev packages
      debug:
        msg: "Dev package: {{ item }}"
      loop: "{{ dev_packages }}"

    - name: Show all packages combined
      debug:
        msg: "All packages: {{ base_packages + dev_packages }}"
```

### Example 3: Directory Structure Creation

```yaml
---
- hosts: all
  vars:
    project_structure:
      - path: /tmp/myproject
        mode: '0755'
      - path: /tmp/myproject/src
        mode: '0755'
      - path: /tmp/myproject/tests
        mode: '0755'
      - path: /tmp/myproject/docs
        mode: '0755'
      - path: /tmp/myproject/config
        mode: '0750'

  tasks:
    - name: Create project directories
      file:
        path: "{{ item.path }}"
        state: directory
        mode: "{{ item.mode }}"
      loop: "{{ project_structure }}"

    - name: Verify structure
      shell: "tree /tmp/myproject || find /tmp/myproject -type d"
      register: tree_output

    - name: Show structure
      debug:
        var: tree_output.stdout_lines
```

### Example 4: Service Management

```yaml
---
- hosts: all
  vars:
    services:
      - name: nginx
        state: started
        enabled: yes
      - name: redis
        state: started
        enabled: yes
      - name: memcached
        state: stopped
        enabled: no

  tasks:
    - name: Manage services
      debug:
        msg: |
          Service: {{ item.name }}
          State: {{ item.state }}
          Enabled: {{ item.enabled }}
      loop: "{{ services }}"
      loop_control:
        label: "{{ item.name }}"
```

### Example 5: Conditional Loop

```yaml
---
- hosts: all
  vars:
    packages:
      - name: nginx
        install: true
      - name: apache2
        install: false
      - name: vim
        install: true
      - name: emacs
        install: false

  tasks:
    - name: Install only selected packages
      debug:
        msg: "Installing {{ item.name }}"
      loop: "{{ packages }}"
      when: item.install
      loop_control:
        label: "{{ item.name }}"

# Only processes nginx and vim
```

---

## Summary

In this section, you learned:

1. **Why loops**: Reduce repetition, cleaner playbooks
2. **Simple loops**: Basic list iteration with `loop`
3. **Loop index**: Access iteration index with `loop_control`
4. **Dictionary loops**: `dict2items` and list of dicts
5. **Nested loops**: `subelements` and `product`
6. **Loop control**: Custom variables, labels, pausing
7. **Registering output**: Capture results from looped tasks

---

## Next Steps

Continue to [Section 7: Conditionals](./SECTION_7.md) to learn how to execute tasks based on conditions.

---

## Quick Reference

```yaml
# Simple loop
loop:
  - item1
  - item2

# Loop with variable
loop: "{{ my_list }}"

# Dictionary loop
loop: "{{ my_dict | dict2items }}"
# Access: item.key, item.value

# Loop with index
loop_control:
  index_var: my_idx
  extended: yes  # Enables ansible_loop.*

# Custom loop variable
loop_control:
  loop_var: my_item

# Clean output
loop_control:
  label: "{{ item.name }}"

# Register loop results
register: results
# Access: results.results[0].item
```
