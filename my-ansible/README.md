# Ansible Hands-On Lab Tutorial

A comprehensive, hands-on Ansible tutorial with working examples and detailed documentation.

## Overview

This tutorial provides a complete introduction to Ansible automation, from basic concepts to advanced features like roles, tags, and Galaxy collections.

```
┌─────────────────────────────────────────────────────────────────┐
│                    ANSIBLE TUTORIAL                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐       │
│   │ Section │   │ Section │   │ Section │   │ Section │       │
│   │  1-3    │──▶│  4-6    │──▶│  7-9    │──▶│ 10-12   │       │
│   │ Basics  │   │Variables│   │ Control │   │Advanced │       │
│   └─────────┘   │  Facts  │   │  Flow   │   │ Topics  │       │
│                 │  Loops  │   │ Handlers│   │ Roles   │       │
│   • Setup       └─────────┘   │  Errors │   │ Tags    │       │
│   • Inventory                 └─────────┘   │ Galaxy  │       │
│   • Playbooks                               └─────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Navigate to the project
cd my-ansible

# 2. Verify Ansible is installed
ansible --version

# 3. Test connectivity
ansible all -m ping

# 4. Run your first playbook
ansible-playbook first-playbook.yml
```

## Tutorial Sections

### Part 1: Foundation

| Section | Topic | Description |
|---------|-------|-------------|
| [Section 1](docs/SECTION_1.md) | **Introduction & Lab Setup** | Ansible concepts, architecture, environment setup |
| [Section 2](docs/SECTION_2.md) | **Inventory & Configuration** | Host management, groups, ansible.cfg |
| [Section 3](docs/SECTION_3.md) | **Ad-hoc Commands & Playbooks** | Running commands, first playbook |

### Part 2: Data & Logic

| Section | Topic | Description |
|---------|-------|-------------|
| [Section 4](docs/SECTION_4.md) | **Variables** | Types, precedence, registration |
| [Section 5](docs/SECTION_5.md) | **Facts** | System information gathering |
| [Section 6](docs/SECTION_6.md) | **Loops** | Iterating over lists and dictionaries |

### Part 3: Control Flow

| Section | Topic | Description |
|---------|-------|-------------|
| [Section 7](docs/SECTION_7.md) | **Conditionals** | when statements, operators |
| [Section 8](docs/SECTION_8.md) | **Handlers** | Triggered tasks, notify/handler |
| [Section 9](docs/SECTION_9.md) | **Error Handling** | ignore_errors, block/rescue/always |

### Part 4: Advanced Topics

| Section | Topic | Description |
|---------|-------|-------------|
| [Section 10](docs/SECTION_10.md) | **Roles** | Reusable automation components |
| [Section 11](docs/SECTION_11.md) | **Tags** | Selective task execution |
| [Section 12](docs/SECTION_12.md) | **Ansible Galaxy** | Collections, FQCN, community content |

## Project Structure

```
my-ansible/
├── README.md                 # This file
├── ansible.cfg               # Ansible configuration
├── inventory                 # Host inventory
│
├── docs/                     # Detailed documentation
│   ├── SECTION_1.md         # Introduction & Lab Setup
│   ├── SECTION_2.md         # Inventory & Configuration
│   ├── SECTION_3.md         # Ad-hoc Commands & Playbooks
│   ├── SECTION_4.md         # Variables
│   ├── SECTION_5.md         # Facts
│   ├── SECTION_6.md         # Loops
│   ├── SECTION_7.md         # Conditionals
│   ├── SECTION_8.md         # Handlers
│   ├── SECTION_9.md         # Error Handling
│   ├── SECTION_10.md        # Roles
│   ├── SECTION_11.md        # Tags
│   └── SECTION_12.md        # Ansible Galaxy
│
├── vars/                     # Variable files
│   └── users.yml
│
├── roles/                    # Custom roles
│   └── my-role/
│       ├── defaults/main.yml
│       ├── vars/main.yml
│       ├── tasks/main.yml
│       └── handlers/main.yml
│
└── *.yml                     # Example playbooks
    ├── first-playbook.yml
    ├── facts.yml
    ├── loop-example.yml
    ├── when-task.yml
    ├── handler-sample.yml
    ├── block-example.yml
    ├── use-role.yml
    ├── tags-example.yml
    └── collection-example.yml
```

## Example Playbooks

### Basic Examples

| Playbook | Concepts | Description |
|----------|----------|-------------|
| `first-playbook.yml` | Basics | Hello World playbook |
| `facts.yml` | Facts | Display system information |
| `loop-example.yml` | Loops | Create multiple users |
| `make-file.yml` | Dict loops | Create files from dictionary |

### Conditional Examples

| Playbook | Concepts | Description |
|----------|----------|-------------|
| `when-task.yml` | Conditionals | Task with condition (true) |
| `when-task-false.yml` | Conditionals | Skipped task example |
| `check-os.yml` | Facts + Conditionals | OS detection |

### Error Handling Examples

| Playbook | Concepts | Description |
|----------|----------|-------------|
| `ignore-example.yml` | ignore_errors | Continue on failure |
| `block-example.yml` | block/rescue/always | Try-catch-finally pattern |
| `handler-sample.yml` | Handlers | Notify/handler pattern |

### Advanced Examples

| Playbook | Concepts | Description |
|----------|----------|-------------|
| `use-role.yml` | Roles | Using custom role |
| `use-role-with-vars.yml` | Roles + Variables | Role with overrides |
| `tags-example.yml` | Tags | Selective execution |
| `collection-example.yml` | Galaxy | Using collections |

## Key Concepts Quick Reference

### Inventory

```ini
# inventory
[webservers]
web1 ansible_host=192.168.1.10

[databases]
db1 ansible_host=192.168.1.20

[all:vars]
ansible_user=admin
```

### Playbook Structure

```yaml
---
- name: Play name
  hosts: webservers
  become: yes

  vars:
    my_var: value

  tasks:
    - name: Task name
      module_name:
        param: value
      notify: handler_name

  handlers:
    - name: handler_name
      module_name:
        param: value
```

### Variables

```yaml
# Precedence (lowest to highest):
# 1. Role defaults
# 2. Group vars
# 3. Host vars
# 4. Play vars
# 5. Task vars
# 6. Extra vars (-e)

# Usage
{{ my_var }}
{{ my_dict.key }}
{{ my_list[0] }}
{{ var | default('fallback') }}
```

### Conditionals

```yaml
when: var == "value"
when: var is defined
when: "'item' in my_list"
when: ansible_facts['os_family'] == "Debian"
when:
  - condition1
  - condition2
```

### Loops

```yaml
loop:
  - item1
  - item2

loop: "{{ my_list }}"

loop: "{{ my_dict | dict2items }}"
# Access: item.key, item.value
```

### Error Handling

```yaml
# Continue on error
ignore_errors: yes

# Try-catch-finally
block:
  - risky_task
rescue:
  - handle_failure
always:
  - cleanup_task
```

### Tags

```bash
# Run with tags
ansible-playbook playbook.yml --tags install

# Skip tags
ansible-playbook playbook.yml --skip-tags test

# List tags
ansible-playbook playbook.yml --list-tags
```

## Running the Examples

```bash
# Test connectivity
ansible all -m ping

# Run ad-hoc command
ansible all -m shell -a "hostname"

# Run playbook
ansible-playbook first-playbook.yml

# Run with verbosity
ansible-playbook playbook.yml -v

# Dry run
ansible-playbook playbook.yml --check

# With tags
ansible-playbook tags-example.yml --tags install
```

## Requirements

- **Ansible**: 2.10+ (tested with 2.18)
- **Python**: 3.8+
- **OS**: macOS, Linux, or WSL

### Installation

```bash
# macOS
brew install ansible

# Ubuntu/Debian
apt-get install ansible

# pip
pip install ansible
```

## Learning Path

```
Week 1: Sections 1-4 (Basics, Inventory, Playbooks, Variables)
        └── Practice: Write playbooks with variables

Week 2: Sections 5-7 (Facts, Loops, Conditionals)
        └── Practice: OS-agnostic playbooks

Week 3: Sections 8-9 (Handlers, Error Handling)
        └── Practice: Robust playbooks with error handling

Week 4: Sections 10-12 (Roles, Tags, Galaxy)
        └── Practice: Create reusable roles
```

## Tips for Success

1. **Read the docs**: `ansible-doc module_name`
2. **Start simple**: Begin with debug module
3. **Use check mode**: `--check` before running
4. **Be verbose**: `-v`, `-vv`, `-vvv` for debugging
5. **Iterate**: Test small changes frequently

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [Jinja2 Template Documentation](https://jinja.palletsprojects.com/)

## License

This tutorial is provided for educational purposes.

---

**Happy Automating!**
