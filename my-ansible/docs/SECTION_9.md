# Section 9: Error Handling

## Table of Contents
- [Understanding Errors in Ansible](#understanding-errors-in-ansible)
- [ignore_errors](#ignore_errors)
- [failed_when](#failed_when)
- [changed_when](#changed_when)
- [Block, Rescue, Always](#block-rescue-always)
- [Error Handling Strategies](#error-handling-strategies)
- [Practical Examples](#practical-examples)

---

## Understanding Errors in Ansible

By default, Ansible **stops execution** when a task fails.

### Default Behavior

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEFAULT ERROR BEHAVIOR                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Task 1: Install package       ✓ OK                             │
│          │                                                       │
│          ▼                                                       │
│  Task 2: Run command           ✗ FAILED                         │
│          │                                                       │
│          ▼                                                       │
│     ╔════════════════════════════════════════════╗              │
│     ║  PLAY ABORTED - Remaining tasks skipped!   ║              │
│     ╚════════════════════════════════════════════╝              │
│                                                                  │
│  Task 3: Start service         ⊘ SKIPPED (never ran)           │
│  Task 4: Verify service        ⊘ SKIPPED (never ran)           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Error Handling Options

| Method | Purpose | Use Case |
|--------|---------|----------|
| `ignore_errors` | Continue despite failure | Non-critical tasks |
| `failed_when` | Custom failure conditions | Define what "failure" means |
| `changed_when` | Custom change detection | Control "changed" status |
| `block/rescue/always` | Try-catch-finally pattern | Complex error handling |

---

## ignore_errors

Continue playbook execution even when a task fails.

### Basic Usage

```yaml
# ignore-example.yml
---
- hosts: all
  tasks:
    - name: This task will fail (command not found)
      shell: "nonexistent_command"
      ignore_errors: yes              # Continue even if this fails

    - name: This task still runs despite the error above
      debug:
        msg: "Execution continued after ignored error!"
```

**Output:**
```
TASK [This task will fail] *****************************************************
fatal: [localhost]: FAILED! => {"msg": "...nonexistent_command: not found..."}
...ignoring

TASK [This task still runs] ****************************************************
ok: [localhost] => {
    "msg": "Execution continued after ignored error!"
}
```

### When to Use ignore_errors

```yaml
---
- hosts: all
  tasks:
    # Good: Non-critical cleanup that might fail
    - name: Remove old temp files (might not exist)
      file:
        path: /tmp/old_cache
        state: absent
      ignore_errors: yes

    # Good: Check that might fail on some systems
    - name: Check optional service
      shell: "systemctl status optional-service"
      ignore_errors: yes
      register: service_check

    # Bad: Don't ignore critical errors!
    - name: Install required package
      apt:
        name: critical-package
        state: present
      # ignore_errors: yes  # DON'T DO THIS!
```

### Capturing Ignored Errors

```yaml
---
- hosts: all
  tasks:
    - name: Try risky operation
      shell: "might_fail_command"
      ignore_errors: yes
      register: risky_result

    - name: Handle based on result
      debug:
        msg: "Operation failed: {{ risky_result.stderr }}"
      when: risky_result.failed

    - name: Proceed if successful
      debug:
        msg: "Operation succeeded!"
      when: not risky_result.failed
```

---

## failed_when

Define **custom conditions** for what constitutes a failure.

### Basic Usage

```yaml
---
- hosts: all
  tasks:
    # Normally, non-zero exit code = failure
    # Here we customize: only fail if exit code > 1
    - name: Run command with custom failure
      shell: "grep 'pattern' /tmp/file.txt"
      register: grep_result
      failed_when: grep_result.rc > 1
      # rc=0: found, rc=1: not found, rc>1: error

    - name: Check string in output
      shell: "cat /var/log/app.log"
      register: log_content
      failed_when: "'FATAL' in log_content.stdout"
```

### Multiple Failure Conditions

```yaml
---
- hosts: all
  tasks:
    - name: Complex failure check
      shell: "some_command"
      register: result
      failed_when:
        - result.rc != 0
        - "'error' in result.stderr"
        # Both conditions must be true to fail (AND logic)

    - name: OR failure conditions
      shell: "some_command"
      register: result
      failed_when: result.rc != 0 or 'critical' in result.stdout
```

### Never Fail

```yaml
---
- hosts: all
  tasks:
    - name: Never fail (use with caution!)
      shell: "risky_command"
      failed_when: false
      register: result

    - name: Check result manually
      fail:
        msg: "Command had issues: {{ result.stderr }}"
      when: result.rc != 0 and 'expected_error' not in result.stderr
```

---

## changed_when

Control when Ansible reports a task as **"changed"**.

### Basic Usage

```yaml
---
- hosts: all
  tasks:
    # Shell always reports "changed" by default
    - name: Check disk space (read-only, not a change)
      shell: "df -h"
      register: disk_info
      changed_when: false        # Never report as changed

    - name: Report change only if certain output
      shell: "apt-get upgrade -s"  # Simulate upgrade
      register: upgrade_check
      changed_when: "'0 upgraded' not in upgrade_check.stdout"
```

### Combined with failed_when

```yaml
---
- hosts: all
  tasks:
    - name: Database migration
      shell: "/opt/app/migrate.sh"
      register: migration
      changed_when: "'Applied' in migration.stdout"
      failed_when: "'Error' in migration.stderr"
```

### Conditional Change Detection

```yaml
---
- hosts: all
  tasks:
    - name: Update config if different
      shell: |
        if diff /etc/app/config.new /etc/app/config.current > /dev/null; then
          echo "NO_CHANGE"
        else
          cp /etc/app/config.new /etc/app/config.current
          echo "UPDATED"
        fi
      register: config_update
      changed_when: "'UPDATED' in config_update.stdout"
```

---

## Block, Rescue, Always

**Try-catch-finally** pattern for Ansible.

### Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    BLOCK / RESCUE / ALWAYS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  block:        ← TRY (main tasks)                               │
│    │                                                             │
│    ├── Task 1 ──────────┐                                       │
│    ├── Task 2           │                                       │
│    └── Task 3 ──────────┤                                       │
│                         │                                        │
│        ┌────────────────┴────────────────┐                      │
│        │                                 │                      │
│        ▼                                 ▼                      │
│    SUCCESS                           FAILURE                    │
│        │                                 │                      │
│        │                                 ▼                      │
│        │                          rescue:      ← CATCH          │
│        │                            │                           │
│        │                            ├── Handle error            │
│        │                            └── Recovery tasks          │
│        │                                 │                      │
│        └─────────────────┬───────────────┘                      │
│                          │                                       │
│                          ▼                                       │
│                    always:         ← FINALLY                    │
│                      │                                          │
│                      ├── Cleanup tasks                          │
│                      └── Always runs (success or failure)       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Basic Syntax

```yaml
---
- hosts: all
  tasks:
    - name: Error handling example
      block:
        # These are the main tasks (try)
        - name: Task that might fail
          shell: "risky_command"

        - name: Another task
          debug:
            msg: "This runs if above succeeds"

      rescue:
        # These run if block fails (catch)
        - name: Handle the error
          debug:
            msg: "Something went wrong, handling it..."

        - name: Recovery action
          debug:
            msg: "Attempting recovery..."

      always:
        # These always run (finally)
        - name: Cleanup
          debug:
            msg: "Cleaning up regardless of success/failure"
```

### Complete Example (From Lab)

```yaml
# block-example.yml
---
- hosts: all
  vars:
    logdir: /tmp/daily_log
    logfile: todays.log

  tasks:
    - name: Configure Log Environment
      block:
        - name: Check if directory exists
          stat:
            path: "{{ logdir }}"
          register: dir_stat

        - name: Fail if directory doesn't exist
          fail:
            msg: "Directory {{ logdir }} does not exist!"
          when: not dir_stat.stat.exists

      rescue:
        - name: Create directory when not found
          file:
            path: "{{ logdir }}"
            state: directory
            mode: '0755'

      always:
        - name: Create log file (always runs)
          file:
            path: "{{ logdir }}/{{ logfile }}"
            state: touch
            mode: '0644'

        - name: Show final result
          shell: "ls -la {{ logdir }}/"
          register: result

        - name: Display directory contents
          debug:
            msg: "{{ result.stdout_lines }}"
```

**First Run (directory doesn't exist):**
```
TASK [Check if directory exists] ***********************************************
ok: [localhost]

TASK [Fail if directory doesn't exist] *****************************************
fatal: [localhost]: FAILED! => {"msg": "Directory /tmp/daily_log does not exist!"}

TASK [Create directory when not found] *****************************************
changed: [localhost]          ← rescue ran

TASK [Create log file (always runs)] *******************************************
changed: [localhost]          ← always ran

TASK [Display directory contents] **********************************************
ok: [localhost] => {"msg": ["total 0", "...", "todays.log"]}
```

**Second Run (directory exists):**
```
TASK [Check if directory exists] ***********************************************
ok: [localhost]

TASK [Fail if directory doesn't exist] *****************************************
skipping: [localhost]         ← block succeeded, no failure

                              ← rescue skipped (no failure)

TASK [Create log file (always runs)] *******************************************
changed: [localhost]          ← always ran anyway
```

---

## Error Handling Strategies

### Strategy 1: Fail Fast (Default)

```yaml
---
- hosts: all
  tasks:
    - name: Critical task
      shell: "important_command"
      # Fails immediately, stops play
```

### Strategy 2: Fail Slow (Collect All Errors)

```yaml
---
- hosts: all
  ignore_unreachable: yes
  max_fail_percentage: 100    # Continue even if all hosts fail

  tasks:
    - name: Check all servers
      shell: "health_check"
      ignore_errors: yes
      register: results

    - name: Report failures at end
      debug:
        msg: "These servers had issues: ..."
```

### Strategy 3: Graceful Degradation

```yaml
---
- hosts: all
  tasks:
    - name: Try primary action
      block:
        - name: Primary method
          shell: "primary_command"
      rescue:
        - name: Fallback method
          shell: "fallback_command"
```

### Strategy 4: any_errors_fatal

```yaml
---
- hosts: webservers
  any_errors_fatal: true      # If ANY host fails, stop entire play

  tasks:
    - name: Critical update
      apt:
        name: security-patch
        state: present
```

---

## Practical Examples

### Example 1: Service Health Check

```yaml
---
- hosts: all
  tasks:
    - name: Health check block
      block:
        - name: Check service is running
          shell: "systemctl is-active myservice"
          register: service_status

        - name: Check service is responding
          uri:
            url: "http://localhost:8080/health"
            status_code: 200
          register: health_check

      rescue:
        - name: Restart service
          service:
            name: myservice
            state: restarted

        - name: Wait for service
          wait_for:
            port: 8080
            timeout: 60

      always:
        - name: Log health check result
          debug:
            msg: |
              Service Status: {{ service_status.stdout | default('unknown') }}
              Health Check: {{ 'passed' if not health_check.failed | default(true) else 'failed' }}
```

### Example 2: Safe File Operations

```yaml
---
- hosts: all
  tasks:
    - name: Safe file update
      block:
        - name: Backup existing file
          copy:
            src: /etc/app/config.yml
            dest: /etc/app/config.yml.bak
            remote_src: yes

        - name: Apply new configuration
          template:
            src: config.yml.j2
            dest: /etc/app/config.yml

        - name: Validate configuration
          shell: "/opt/app/validate-config.sh"

      rescue:
        - name: Restore backup on failure
          copy:
            src: /etc/app/config.yml.bak
            dest: /etc/app/config.yml
            remote_src: yes

        - name: Alert about failure
          debug:
            msg: "Configuration update FAILED! Backup restored."

      always:
        - name: Clean up backup
          file:
            path: /etc/app/config.yml.bak
            state: absent
          when: cleanup_backups | default(true)
```

### Example 3: Database Migration

```yaml
---
- hosts: databases
  tasks:
    - name: Database migration
      block:
        - name: Create backup
          shell: "pg_dump mydb > /backup/pre_migration.sql"

        - name: Run migrations
          shell: "/opt/app/migrate.sh"
          register: migration_result
          failed_when: "'ERROR' in migration_result.stderr"

        - name: Verify data integrity
          shell: "/opt/app/verify_db.sh"

      rescue:
        - name: Rollback migration
          shell: "psql mydb < /backup/pre_migration.sql"

        - name: Send alert
          debug:
            msg: "ALERT: Database migration failed and was rolled back!"

      always:
        - name: Record migration status
          lineinfile:
            path: /var/log/migrations.log
            line: "{{ ansible_date_time.iso8601 }} - Migration {{ 'SUCCESS' if not ansible_failed_task is defined else 'FAILED' }}"
            create: yes
```

### Example 4: Multi-Step Deployment

```yaml
---
- hosts: app_servers
  tasks:
    - name: Application deployment
      block:
        - name: Stop application
          service:
            name: myapp
            state: stopped

        - name: Deploy new version
          unarchive:
            src: "https://releases.example.com/app-{{ version }}.tar.gz"
            dest: /opt/app/
            remote_src: yes

        - name: Run database migrations
          shell: "/opt/app/migrate.sh"

        - name: Start application
          service:
            name: myapp
            state: started

        - name: Verify application
          uri:
            url: "http://localhost:8080/health"
            status_code: 200
          retries: 5
          delay: 10

      rescue:
        - name: Rollback to previous version
          shell: "/opt/app/rollback.sh"

        - name: Start previous version
          service:
            name: myapp
            state: started

        - name: Notify failure
          debug:
            msg: "Deployment of {{ version }} FAILED - rolled back"

      always:
        - name: Clean up temp files
          file:
            path: /tmp/deploy_temp
            state: absent
```

---

## Summary

In this section, you learned:

1. **Default behavior**: Ansible stops on failure
2. **ignore_errors**: Continue despite failures
3. **failed_when**: Custom failure conditions
4. **changed_when**: Control change reporting
5. **block/rescue/always**: Try-catch-finally pattern
6. **Strategies**: Fail fast, fail slow, graceful degradation

---

## Next Steps

Continue to [Section 10: Roles](./SECTION_10.md) to learn about organizing playbooks into reusable components.

---

## Quick Reference

```yaml
# Ignore errors
ignore_errors: yes

# Custom failure condition
failed_when: result.rc > 1
failed_when: "'error' in result.stderr"

# Custom change condition
changed_when: false
changed_when: "'updated' in result.stdout"

# Block structure
block:
  - name: Try this
    shell: "command"
rescue:
  - name: Handle failure
    debug:
      msg: "Failed!"
always:
  - name: Always run
    debug:
      msg: "Cleanup"

# Stop all hosts on any failure
any_errors_fatal: true
```
