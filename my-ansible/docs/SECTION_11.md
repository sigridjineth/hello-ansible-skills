# Section 11: Tags

## Table of Contents
- [What are Tags?](#what-are-tags)
- [Defining Tags](#defining-tags)
- [Running with Tags](#running-with-tags)
- [Special Tags](#special-tags)
- [Tag Inheritance](#tag-inheritance)
- [Practical Examples](#practical-examples)
- [Best Practices](#best-practices)

---

## What are Tags?

Tags allow you to **selectively run** parts of a playbook.

### Why Use Tags?

```
┌─────────────────────────────────────────────────────────────────┐
│                       TAG USE CASES                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  FULL DEPLOYMENT (all tasks)                                    │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐                    │
│  │ 1  │→│ 2  │→│ 3  │→│ 4  │→│ 5  │→│ 6  │                    │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘                    │
│  install config  deploy verify  test  cleanup                  │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  QUICK CONFIG UPDATE (--tags config)                           │
│  ┌────┐                                                         │
│  │ 2  │  Only runs "config" tagged tasks                       │
│  └────┘                                                         │
│  config                                                         │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  SKIP TESTS (--skip-tags test)                                 │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       ┌────┐                     │
│  │ 1  │→│ 2  │→│ 3  │→│ 4  │──────→│ 6  │  Skips "test"       │
│  └────┘ └────┘ └────┘ └────┘       └────┘                     │
│  install config  deploy verify     cleanup                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Common Use Cases

| Use Case | Command | Purpose |
|----------|---------|---------|
| Quick test | `--tags test` | Run only tests |
| Skip slow tasks | `--skip-tags slow` | Skip time-consuming tasks |
| Config only | `--tags config` | Update configs without reinstall |
| Debug | `--tags debug` | Run debug tasks only |
| Partial deploy | `--tags deploy` | Deploy without full setup |

---

## Defining Tags

### Task-Level Tags

```yaml
---
- hosts: all
  tasks:
    - name: Install packages
      apt:
        name: nginx
        state: present
      tags:
        - install
        - packages

    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags:
        - config
        - nginx

    - name: Start service
      service:
        name: nginx
        state: started
      tags:
        - service
```

### Single Tag (Shorthand)

```yaml
- name: Simple task
  debug:
    msg: "Hello"
  tags: debug                    # Single tag, no list needed
```

### Multiple Tags

```yaml
- name: Task with multiple tags
  debug:
    msg: "Multiple tags"
  tags:
    - config
    - setup
    - quick                      # Task runs if ANY tag matches
```

### Block-Level Tags

```yaml
---
- hosts: all
  tasks:
    - name: Installation block
      tags: install
      block:
        - name: Install package 1
          debug:
            msg: "Installing 1"

        - name: Install package 2
          debug:
            msg: "Installing 2"

        - name: Install package 3
          debug:
            msg: "Installing 3"
      # All tasks in block inherit "install" tag
```

### Play-Level Tags

```yaml
---
- name: Web server setup
  hosts: webservers
  tags: web
  tasks:
    - name: Task 1
      debug:
        msg: "All tasks in play get 'web' tag"

    - name: Task 2
      debug:
        msg: "This too"
```

### Role Tags

```yaml
---
- hosts: all
  roles:
    - role: common
      tags: common

    - role: nginx
      tags:
        - nginx
        - web

    - role: app
      tags: app
```

---

## Running with Tags

### List Available Tags

```bash
$ ansible-playbook playbook.yml --list-tags

playbook: playbook.yml

  play #1 (all): all    TAGS: []
      TASK TAGS: [always, config, install, service, setup, test]
```

### Run Specific Tags

```bash
# Run tasks with 'install' tag
ansible-playbook playbook.yml --tags install

# Run multiple tags
ansible-playbook playbook.yml --tags "install,config"

# Short form
ansible-playbook playbook.yml -t install
```

### Skip Specific Tags

```bash
# Skip tasks with 'test' tag
ansible-playbook playbook.yml --skip-tags test

# Skip multiple tags
ansible-playbook playbook.yml --skip-tags "test,debug"
```

### Combine --tags and --skip-tags

```bash
# Run 'deploy' but skip 'slow' tasks within it
ansible-playbook playbook.yml --tags deploy --skip-tags slow
```

### List Tasks That Would Run

```bash
# Preview what would run with tags
ansible-playbook playbook.yml --tags install --list-tasks

playbook: playbook.yml

  play #1 (all): all    TAGS: []
    tasks:
      Install packages    TAGS: [install, packages]
```

---

## Special Tags

### always Tag

Tasks tagged with `always` run **regardless of tag filtering**.

```yaml
---
- hosts: all
  tasks:
    - name: This ALWAYS runs
      debug:
        msg: "I run no matter what tags are specified"
      tags: always

    - name: This runs only with 'install' tag
      debug:
        msg: "Install task"
      tags: install

    - name: This runs only with 'config' tag
      debug:
        msg: "Config task"
      tags: config
```

```bash
# Even with --tags install, 'always' task runs
$ ansible-playbook playbook.yml --tags install

TASK [This ALWAYS runs] **************************************
ok: [localhost]

TASK [This runs only with 'install' tag] *********************
ok: [localhost]

# 'config' task is skipped
```

### never Tag

Tasks tagged with `never` only run if **explicitly requested**.

```yaml
---
- hosts: all
  tasks:
    - name: Normal task
      debug:
        msg: "I run by default"

    - name: Debug task (normally skipped)
      debug:
        msg: "Detailed debug info..."
      tags: never

    - name: Dangerous cleanup (normally skipped)
      debug:
        msg: "Deleting everything!"
      tags:
        - never
        - cleanup
```

```bash
# Normal run - 'never' tasks are skipped
$ ansible-playbook playbook.yml
# Only "Normal task" runs

# Explicitly run 'never' tasks
$ ansible-playbook playbook.yml --tags never
# Only tasks with 'never' tag run

# Run cleanup (which has 'never' tag)
$ ansible-playbook playbook.yml --tags cleanup
# Runs the cleanup task
```

---

## Tag Inheritance

### Import vs Include Behavior

**import_tasks (static)**: Tags apply to all imported tasks

```yaml
# main.yml
- import_tasks: install.yml
  tags: install
# All tasks in install.yml get 'install' tag

# install.yml
- name: Task A    # Gets 'install' tag automatically
  debug:
    msg: "A"

- name: Task B    # Gets 'install' tag automatically
  debug:
    msg: "B"
```

**include_tasks (dynamic)**: Tags apply to the include itself

```yaml
# main.yml
- include_tasks: install.yml
  tags: install
# Only the include statement has 'install' tag
# Tasks inside install.yml keep their own tags only
```

### Role Tag Inheritance

```yaml
---
- hosts: all
  roles:
    - role: webserver
      tags: web

# All tasks in webserver role get 'web' tag
```

---

## Practical Examples

### Example 1: Tags Example (From Lab)

```yaml
# tags-example.yml
---
- hosts: all
  tasks:
    - name: "Install packages"
      debug:
        msg: "Installing packages..."
      tags:
        - install
        - setup

    - name: "Configure settings"
      debug:
        msg: "Configuring settings..."
      tags:
        - config
        - setup

    - name: "Start services"
      debug:
        msg: "Starting services..."
      tags:
        - service

    - name: "Run tests"
      debug:
        msg: "Running tests..."
      tags:
        - test

    - name: "Always run this"
      debug:
        msg: "This always runs!"
      tags:
        - always
```

**List tags:**
```bash
$ ansible-playbook tags-example.yml --list-tags

TASK TAGS: [always, config, install, service, setup, test]
```

**Run 'install' tag:**
```bash
$ ansible-playbook tags-example.yml --tags install

TASK [Install packages] ****************************
ok: [localhost] => {"msg": "Installing packages..."}

TASK [Always run this] *****************************
ok: [localhost] => {"msg": "This always runs!"}
```

**Run 'setup' tag (matches multiple tasks):**
```bash
$ ansible-playbook tags-example.yml --tags setup

TASK [Install packages] ****************************
ok: [localhost] => {"msg": "Installing packages..."}

TASK [Configure settings] **************************
ok: [localhost] => {"msg": "Configuring settings..."}

TASK [Always run this] *****************************
ok: [localhost] => {"msg": "This always runs!"}
```

**Skip 'test' tag:**
```bash
$ ansible-playbook tags-example.yml --skip-tags test

# Runs everything except "Run tests"
```

### Example 2: Deployment Playbook

```yaml
---
- hosts: app_servers
  tasks:
    # Always gather facts
    - name: Gather custom facts
      setup:
      tags: always

    # Installation phase
    - name: Install dependencies
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ packages }}"
      tags:
        - install
        - setup

    # Configuration phase
    - name: Deploy configuration
      template:
        src: app.conf.j2
        dest: /etc/app/config.yml
      tags:
        - config
        - deploy

    - name: Set up environment
      template:
        src: env.j2
        dest: /etc/app/.env
      tags:
        - config
        - deploy

    # Deployment phase
    - name: Deploy application
      copy:
        src: app.jar
        dest: /opt/app/
      tags:
        - deploy

    - name: Run database migrations
      shell: "/opt/app/migrate.sh"
      tags:
        - deploy
        - migrate

    # Service management
    - name: Restart application
      service:
        name: app
        state: restarted
      tags:
        - service
        - deploy

    # Verification
    - name: Run smoke tests
      uri:
        url: "http://localhost:8080/health"
        status_code: 200
      tags:
        - test
        - verify

    # Debug (never runs by default)
    - name: Show debug info
      debug:
        var: ansible_facts
      tags:
        - never
        - debug
```

**Usage scenarios:**
```bash
# Full deployment
ansible-playbook deploy.yml

# Quick config update only
ansible-playbook deploy.yml --tags config

# Deploy without running tests
ansible-playbook deploy.yml --tags deploy --skip-tags test

# Just restart service
ansible-playbook deploy.yml --tags service

# Run with debug info
ansible-playbook deploy.yml --tags "deploy,debug"
```

### Example 3: Environment-Specific Tags

```yaml
---
- hosts: all
  tasks:
    - name: Production-only settings
      template:
        src: prod.conf.j2
        dest: /etc/app/prod.conf
      tags:
        - production
        - never          # Won't run unless explicitly tagged

    - name: Development settings
      template:
        src: dev.conf.j2
        dest: /etc/app/dev.conf
      tags:
        - development
        - never

    - name: Common settings
      template:
        src: common.conf.j2
        dest: /etc/app/common.conf
      tags:
        - config
```

```bash
# Production deployment
ansible-playbook playbook.yml --tags "config,production"

# Development setup
ansible-playbook playbook.yml --tags "config,development"
```

---

## Best Practices

### 1. Use Consistent Tag Names

```yaml
# Good: Consistent naming scheme
tags: [install, packages]
tags: [config, nginx]
tags: [service, start]

# Bad: Inconsistent
tags: [setup, pkgs]
tags: [configuration, web-server]
tags: [svc, run]
```

### 2. Document Your Tags

```yaml
# Playbook header comment
# Available tags:
#   - install: Install packages
#   - config: Update configuration
#   - deploy: Deploy application
#   - test: Run tests
#   - service: Manage services
```

### 3. Use Semantic Tag Groups

```yaml
# Lifecycle stages
tags: [setup]
tags: [deploy]
tags: [verify]
tags: [cleanup]

# Component types
tags: [database]
tags: [webserver]
tags: [cache]

# Actions
tags: [install]
tags: [configure]
tags: [start]
tags: [stop]
```

### 4. Use 'always' Sparingly

```yaml
# Good: Essential setup tasks
- name: Gather facts
  setup:
  tags: always

# Bad: Too many 'always' tasks defeats the purpose
- name: Every task is always
  debug:
    msg: "Don't do this"
  tags: always    # Defeats purpose of tags
```

### 5. Use 'never' for Dangerous Tasks

```yaml
- name: Delete all data
  shell: "rm -rf /data/*"
  tags:
    - never
    - dangerous
    - cleanup
```

---

## Summary

In this section, you learned:

1. **What tags are**: Selective task execution
2. **Defining tags**: Task, block, play, and role level
3. **Running with tags**: `--tags` and `--skip-tags`
4. **Special tags**: `always` and `never`
5. **Tag inheritance**: import vs include behavior
6. **Best practices**: Naming, documentation, semantic groups

---

## Next Steps

Continue to [Section 12: Ansible Galaxy](./SECTION_12.md) to learn about sharing and using community content.

---

## Quick Reference

```bash
# List tags
ansible-playbook playbook.yml --list-tags

# Run specific tags
ansible-playbook playbook.yml --tags install
ansible-playbook playbook.yml --tags "install,config"
ansible-playbook playbook.yml -t install

# Skip tags
ansible-playbook playbook.yml --skip-tags test

# Combine
ansible-playbook playbook.yml --tags deploy --skip-tags slow

# List tasks for tags
ansible-playbook playbook.yml --tags install --list-tasks
```

```yaml
# Special tags
tags: always    # Always runs
tags: never     # Never runs unless explicitly requested
tags: [never, cleanup]  # Combine with other tags
```
