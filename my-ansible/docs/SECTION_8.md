# Section 8: Handlers

## Table of Contents
- [What are Handlers?](#what-are-handlers)
- [Handler Basics](#handler-basics)
- [Notify and Handler Relationship](#notify-and-handler-relationship)
- [Handler Execution Order](#handler-execution-order)
- [Multiple Handlers](#multiple-handlers)
- [Handler Best Practices](#handler-best-practices)
- [Practical Examples](#practical-examples)

---

## What are Handlers?

Handlers are **special tasks** that run only when **notified** by other tasks.

### Handler Concept

```
┌─────────────────────────────────────────────────────────────────┐
│                      HANDLER CONCEPT                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  REGULAR TASKS                          HANDLERS                │
│  (Always run in order)                  (Only when notified)    │
│                                                                  │
│  ┌─────────────────────┐                                        │
│  │ Task 1: Update      │                                        │
│  │ nginx config        │─────── notify ──────┐                  │
│  │ (changed: yes)      │                     │                  │
│  └─────────────────────┘                     │                  │
│           │                                  │                  │
│           ▼                                  │                  │
│  ┌─────────────────────┐                     │                  │
│  │ Task 2: Update      │                     │                  │
│  │ SSL cert            │─────── notify ──────┤                  │
│  │ (changed: yes)      │                     │                  │
│  └─────────────────────┘                     │                  │
│           │                                  │                  │
│           ▼                                  │                  │
│  ┌─────────────────────┐                     │                  │
│  │ Task 3: Check       │                     │                  │
│  │ status              │                     │                  │
│  │ (changed: no)       │ ✗ no notify        │                  │
│  └─────────────────────┘                     │                  │
│           │                                  │                  │
│           │                                  ▼                  │
│           │                        ┌─────────────────────┐     │
│           │                        │ Handler: Restart    │     │
│           └───────────────────────►│ nginx               │     │
│                                    │ (runs ONCE at end)  │     │
│                 END OF PLAY        └─────────────────────┘     │
│                                                                  │
│  Key: Handler runs ONCE even if notified multiple times!       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why Use Handlers?

| Scenario | Without Handlers | With Handlers |
|----------|------------------|---------------|
| Config change | Restart immediately | Restart once at end |
| Multiple changes | Multiple restarts | Single restart |
| No changes | Unnecessary restart | No restart |
| Service disruption | Higher | Lower |

---

## Handler Basics

### Basic Syntax

```yaml
---
- hosts: all
  tasks:
    - name: Update configuration
      copy:
        src: app.conf
        dest: /etc/app/app.conf
      notify: restart app         # Trigger handler if changed

  handlers:
    - name: restart app           # Handler name (must match notify)
      debug:
        msg: "Restarting application..."
```

### Handler Execution Rules

1. **Only when notified**: Handlers run only if a task reports `changed`
2. **Run once**: Even if notified multiple times, runs only once
3. **Run at end**: Handlers run at the end of the play (by default)
4. **Run in order**: Handlers run in the order they're defined (not notified)

---

## Notify and Handler Relationship

### Single Notify

```yaml
---
- hosts: all
  tasks:
    - name: Create file (triggers handler)
      file:
        path: /tmp/handler-test.txt
        state: touch
      notify: print msg              # Must match handler name exactly

  handlers:
    - name: print msg                # Handler name
      debug:
        msg: "Handler triggered! File was created/modified."
```

### Multiple Tasks, Same Handler

```yaml
---
- hosts: all
  tasks:
    - name: Update config file 1
      copy:
        content: "setting1=value1"
        dest: /tmp/config1.txt
      notify: restart service

    - name: Update config file 2
      copy:
        content: "setting2=value2"
        dest: /tmp/config2.txt
      notify: restart service        # Same handler

    - name: Update config file 3
      copy:
        content: "setting3=value3"
        dest: /tmp/config3.txt
      notify: restart service        # Same handler

  handlers:
    - name: restart service
      debug:
        msg: "Service restarted ONCE (even though notified 3 times)"
```

### Multiple Handlers from One Task

```yaml
---
- hosts: all
  tasks:
    - name: Deploy application
      copy:
        src: app.jar
        dest: /opt/app/app.jar
      notify:                        # Notify multiple handlers
        - stop old service
        - clear cache
        - start new service

  handlers:
    - name: stop old service
      debug:
        msg: "Stopping old service..."

    - name: clear cache
      debug:
        msg: "Clearing cache..."

    - name: start new service
      debug:
        msg: "Starting new service..."
```

---

## Handler Execution Order

### Handlers Run in Definition Order

```yaml
---
- hosts: all
  tasks:
    - name: Task that notifies in reverse order
      file:
        path: /tmp/test.txt
        state: touch
      notify:
        - handler C
        - handler A
        - handler B

  handlers:
    # Handlers run in THIS order (definition order)
    - name: handler A
      debug:
        msg: "Handler A runs first"

    - name: handler B
      debug:
        msg: "Handler B runs second"

    - name: handler C
      debug:
        msg: "Handler C runs third"

# Output order: A, B, C (not C, A, B)
```

### Force Handler Execution Mid-Play

```yaml
---
- hosts: all
  tasks:
    - name: Update config
      copy:
        content: "new config"
        dest: /tmp/app.conf
      notify: restart app

    - name: Flush handlers NOW
      meta: flush_handlers          # Force handlers to run here

    - name: Continue with more tasks
      debug:
        msg: "App already restarted, continuing..."

  handlers:
    - name: restart app
      debug:
        msg: "Restarting application"
```

---

## Multiple Handlers

### Listen Directive

Multiple handlers can listen to the same notification:

```yaml
---
- hosts: all
  tasks:
    - name: Deploy application
      copy:
        content: "app code"
        dest: /tmp/app.txt
      notify: deploy complete        # Generic notification

  handlers:
    - name: clear cache
      debug:
        msg: "Cache cleared"
      listen: deploy complete        # Listen to notification

    - name: restart app
      debug:
        msg: "App restarted"
      listen: deploy complete        # Same notification

    - name: send notification
      debug:
        msg: "Notification sent"
      listen: deploy complete        # Same notification
```

### Handler Chains

Handlers can notify other handlers:

```yaml
---
- hosts: all
  tasks:
    - name: Update config
      copy:
        content: "config"
        dest: /tmp/config.txt
      notify: validate config

  handlers:
    - name: validate config
      debug:
        msg: "Validating config..."
      notify: restart service        # Chain to another handler

    - name: restart service
      debug:
        msg: "Restarting service..."
      notify: verify service

    - name: verify service
      debug:
        msg: "Verifying service is running..."
```

---

## Handler Best Practices

### 1. Descriptive Handler Names

```yaml
# Good
handlers:
  - name: restart nginx
  - name: reload systemd
  - name: clear application cache

# Bad
handlers:
  - name: handler1
  - name: do stuff
```

### 2. Idempotent Handlers

```yaml
handlers:
  # Good - idempotent
  - name: restart nginx
    service:
      name: nginx
      state: restarted

  # Be careful with shell commands
  - name: reload config
    shell: "nginx -s reload"
    # Consider using service module instead
```

### 3. Use listen for Flexibility

```yaml
handlers:
  # Multiple handlers can respond to one event
  - name: restart web server
    service:
      name: nginx
      state: restarted
    listen: web config changed

  - name: clear varnish cache
    service:
      name: varnish
      state: restarted
    listen: web config changed
```

### 4. Handler Error Handling

```yaml
---
- hosts: all
  tasks:
    - name: Update config
      copy:
        content: "config"
        dest: /tmp/config.txt
      notify: restart app

  handlers:
    - name: restart app
      block:
        - name: Restart service
          service:
            name: myapp
            state: restarted

        - name: Wait for service
          wait_for:
            port: 8080
            timeout: 30
      rescue:
        - name: Service failed to start
          debug:
            msg: "WARNING: Service failed to restart!"
```

---

## Practical Examples

### Example 1: Basic Handler (From Lab)

```yaml
# handler-sample.yml
---
- hosts: all
  tasks:
    - name: Create a file (triggers handler)
      file:
        path: /tmp/handler-test.txt
        state: touch
      notify:
        - print msg

  handlers:
    - name: print msg
      debug:
        msg: "Handler triggered! File was created/modified."
```

**Output when file is created:**
```
TASK [Create a file (triggers handler)] ****************************************
changed: [localhost]

RUNNING HANDLER [print msg] ****************************************************
ok: [localhost] => {
    "msg": "Handler triggered! File was created/modified."
}
```

**Output when file already exists:**
```
TASK [Create a file (triggers handler)] ****************************************
ok: [localhost]

# Handler does NOT run because task did not change anything
```

### Example 2: Web Server Configuration

```yaml
---
- hosts: webservers
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
      notify: start nginx

    - name: Copy nginx config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: reload nginx

    - name: Copy SSL certificate
      copy:
        src: ssl.crt
        dest: /etc/nginx/ssl/
      notify: reload nginx

    - name: Copy SSL key
      copy:
        src: ssl.key
        dest: /etc/nginx/ssl/
        mode: '0600'
      notify: reload nginx

  handlers:
    - name: start nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: reload nginx
      service:
        name: nginx
        state: reloaded
```

### Example 3: Application Deployment

```yaml
---
- hosts: app_servers
  tasks:
    - name: Download application
      get_url:
        url: "https://releases.example.com/app-{{ version }}.jar"
        dest: /opt/app/app.jar
      notify:
        - stop application
        - clear temp files
        - start application

    - name: Update configuration
      template:
        src: application.yml.j2
        dest: /opt/app/config/application.yml
      notify: restart application

  handlers:
    - name: stop application
      service:
        name: myapp
        state: stopped

    - name: clear temp files
      file:
        path: /opt/app/temp
        state: absent

    - name: start application
      service:
        name: myapp
        state: started

    - name: restart application
      service:
        name: myapp
        state: restarted
```

### Example 4: Database Configuration

```yaml
---
- hosts: databases
  tasks:
    - name: Update PostgreSQL config
      lineinfile:
        path: /etc/postgresql/14/main/postgresql.conf
        regexp: "^max_connections"
        line: "max_connections = 200"
      notify: restart postgresql

    - name: Update pg_hba.conf
      template:
        src: pg_hba.conf.j2
        dest: /etc/postgresql/14/main/pg_hba.conf
      notify: reload postgresql

  handlers:
    - name: reload postgresql
      service:
        name: postgresql
        state: reloaded

    - name: restart postgresql
      service:
        name: postgresql
        state: restarted
```

### Example 5: Conditional Handler Execution

```yaml
---
- hosts: all
  vars:
    auto_restart: true

  tasks:
    - name: Update config
      copy:
        content: "new config"
        dest: /tmp/app.conf
      register: config_result
      notify: restart service

  handlers:
    - name: restart service
      debug:
        msg: "Restarting service..."
      when: auto_restart
      # Handler only runs if auto_restart is true
```

---

## Summary

In this section, you learned:

1. **What handlers are**: Special tasks triggered by notifications
2. **Notify/handler relationship**: Tasks notify handlers when changed
3. **Execution rules**: Run once, at end of play, in definition order
4. **Multiple handlers**: Using `listen` and handler chains
5. **Best practices**: Naming, idempotency, error handling

---

## Next Steps

Continue to [Section 9: Error Handling](./SECTION_9.md) to learn about managing task failures.

---

## Quick Reference

```yaml
# Basic handler
tasks:
  - name: Task
    file:
      path: /tmp/file
      state: touch
    notify: my handler

handlers:
  - name: my handler
    debug:
      msg: "Handler ran!"

# Multiple notifications
notify:
  - handler 1
  - handler 2

# Listen directive
handlers:
  - name: handler a
    debug:
      msg: "A"
    listen: common event

  - name: handler b
    debug:
      msg: "B"
    listen: common event

# Force handlers mid-play
- meta: flush_handlers
```
