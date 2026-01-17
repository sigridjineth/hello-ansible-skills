# Section 10: Ansible Roles

## Table of Contents
- [What are Roles?](#what-are-roles)
- [Role Directory Structure](#role-directory-structure)
- [Creating Roles](#creating-roles)
- [Using Roles in Playbooks](#using-roles-in-playbooks)
- [Role Variables](#role-variables)
- [Role Dependencies](#role-dependencies)
- [Practical Examples](#practical-examples)
- [Best Practices](#best-practices)

---

## What are Roles?

Roles are a way to **organize and reuse** Ansible automation content.

### Why Use Roles?

```
┌─────────────────────────────────────────────────────────────────┐
│                    WITHOUT ROLES (Monolithic)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  site.yml (500+ lines)                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ - Install web server                                     │   │
│  │ - Configure web server                                   │   │
│  │ - Install database                                       │   │
│  │ - Configure database                                     │   │
│  │ - Install app                                            │   │
│  │ - Configure app                                          │   │
│  │ - Set up monitoring                                      │   │
│  │ - Configure logging                                      │   │
│  │ - ... hundreds more tasks ...                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Problems: Hard to maintain, not reusable, difficult to test   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      WITH ROLES (Modular)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  site.yml (10 lines)                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ - hosts: webservers                                      │   │
│  │   roles:                                                 │   │
│  │     - common                                             │   │
│  │     - nginx                                              │   │
│  │     - app                                                │   │
│  │                                                          │   │
│  │ - hosts: databases                                       │   │
│  │   roles:                                                 │   │
│  │     - common                                             │   │
│  │     - postgresql                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Each role is self-contained, reusable, and testable!          │
│                                                                  │
│  roles/                                                         │
│  ├── common/        ← Shared configuration                     │
│  ├── nginx/         ← Web server role                          │
│  ├── postgresql/    ← Database role                            │
│  └── app/           ← Application role                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Role Benefits

| Benefit | Description |
|---------|-------------|
| **Reusability** | Use same role across projects |
| **Organization** | Clear structure and separation |
| **Testability** | Test roles independently |
| **Shareability** | Publish to Ansible Galaxy |
| **Maintainability** | Easier to update and debug |

---

## Role Directory Structure

### Standard Structure

```
roles/
└── my-role/
    ├── defaults/
    │   └── main.yml        # Default variables (lowest precedence)
    ├── vars/
    │   └── main.yml        # Role variables (higher precedence)
    ├── tasks/
    │   └── main.yml        # Main task list
    ├── handlers/
    │   └── main.yml        # Handler definitions
    ├── files/
    │   └── ...             # Static files to copy
    ├── templates/
    │   └── ...             # Jinja2 templates
    ├── meta/
    │   └── main.yml        # Role metadata and dependencies
    ├── tests/
    │   ├── inventory
    │   └── test.yml        # Test playbook
    └── README.md           # Documentation
```

### Directory Purposes

| Directory | Purpose | Loaded Automatically |
|-----------|---------|---------------------|
| `defaults/` | Default variable values | Yes |
| `vars/` | Role-specific variables | Yes |
| `tasks/` | Task definitions | Yes (`main.yml`) |
| `handlers/` | Handler definitions | Yes (`main.yml`) |
| `files/` | Static files for `copy` module | Referenced by path |
| `templates/` | Jinja2 templates | Referenced by path |
| `meta/` | Role metadata, dependencies | Yes |
| `tests/` | Role testing files | No |

---

## Creating Roles

### Using ansible-galaxy

```bash
# Create new role with standard structure
$ ansible-galaxy role init my-role

- Role my-role was created successfully

$ tree my-role/
my-role/
├── README.md
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml
```

### Manual Creation

```bash
# Create minimal role structure
mkdir -p roles/my-role/{tasks,handlers,defaults,vars,files,templates}
touch roles/my-role/tasks/main.yml
touch roles/my-role/handlers/main.yml
touch roles/my-role/defaults/main.yml
```

---

## Using Roles in Playbooks

### Method 1: roles Section

```yaml
---
- hosts: webservers
  roles:
    - common                    # Simple role reference
    - nginx
    - role: app                 # With parameters
      vars:
        app_port: 8080
```

### Method 2: import_role (Static)

```yaml
---
- hosts: webservers
  tasks:
    - name: Include common role
      import_role:
        name: common

    - name: Configure web server
      import_role:
        name: nginx
      vars:
        nginx_port: 80
```

### Method 3: include_role (Dynamic)

```yaml
---
- hosts: webservers
  tasks:
    - name: Dynamically include role
      include_role:
        name: "{{ role_name }}"
      loop:
        - common
        - nginx
      loop_control:
        loop_var: role_name
```

### import_role vs include_role

| Feature | import_role | include_role |
|---------|-------------|--------------|
| Processing | Static (pre-processed) | Dynamic (runtime) |
| Conditionals | Applied to all tasks | Applied to include only |
| Loops | Not supported | Supported |
| Handlers | Visible globally | Scoped to include |
| Tags | Inherited by tasks | Applied to include |

---

## Role Variables

### defaults/main.yml (Lowest Precedence)

```yaml
# roles/my-role/defaults/main.yml
---
# These can be easily overridden
web_root: /var/www/html
web_port: 80
web_user: www-data
enable_ssl: false
```

### vars/main.yml (Higher Precedence)

```yaml
# roles/my-role/vars/main.yml
---
# These are harder to override (use for constants)
web_config_path: /etc/nginx/nginx.conf
required_packages:
  - nginx
  - openssl
```

### Variable Override Example

```yaml
# group_vars/webservers.yml
web_port: 8080                    # Overrides defaults/main.yml

# Playbook
---
- hosts: webservers
  roles:
    - role: my-role
      vars:
        web_port: 9000            # Overrides group_vars
```

### Precedence (Role Context)

```
LOWEST                                                      HIGHEST
   │                                                            │
   ▼                                                            ▼
┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
│ Role   │→ │ Inven- │→ │ Play   │→ │ Role   │→ │ Role   │→ │ -e     │
│defaults│  │ tory   │  │ vars   │  │ vars/  │  │ params │  │        │
└────────┘  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘
```

---

## Role Dependencies

### Defining Dependencies

```yaml
# roles/app/meta/main.yml
---
dependencies:
  - role: common
  - role: nginx
    vars:
      nginx_port: 8080
  - role: postgresql
    when: use_database | default(true)
```

### Dependency Behavior

```
When you run the 'app' role:

1. First: 'common' role runs
2. Then:  'nginx' role runs (with nginx_port=8080)
3. Then:  'postgresql' role runs (if use_database is true)
4. Finally: 'app' role tasks run
```

### Preventing Duplicate Execution

```yaml
# roles/common/meta/main.yml
---
allow_duplicates: false       # Default: won't run twice
# allow_duplicates: true      # Would run multiple times
```

---

## Practical Examples

### Example 1: Web Server Role (From Lab)

**Role Structure:**
```
roles/my-role/
├── defaults/main.yml
├── vars/main.yml
├── tasks/main.yml
└── handlers/main.yml
```

**defaults/main.yml:**
```yaml
---
# Easily overridable defaults
web_root: /tmp/web_content
web_index: index.html
web_message: "Hello from Ansible Role!"
```

**vars/main.yml:**
```yaml
---
# Higher precedence variables
web_owner: "{{ ansible_user_id }}"
```

**tasks/main.yml:**
```yaml
---
- name: Create web root directory
  file:
    path: "{{ web_root }}"
    state: directory
    mode: '0755'

- name: Create index.html file
  copy:
    dest: "{{ web_root }}/{{ web_index }}"
    content: |
      <html>
      <head><title>Ansible Role Demo</title></head>
      <body>
        <h1>{{ web_message }}</h1>
        <p>Owner: {{ web_owner }}</p>
        <p>Created by: my-role</p>
      </body>
      </html>
    mode: '0644'
  notify: show web content

- name: Display web setup info
  debug:
    msg: "Web content created at {{ web_root }}/{{ web_index }}"
```

**handlers/main.yml:**
```yaml
---
- name: show web content
  shell: "cat {{ web_root }}/{{ web_index }}"
  register: cat_result

- name: display content
  debug:
    msg: "{{ cat_result.stdout_lines }}"
  listen: show web content
```

### Example 2: Using the Role

**Simple usage:**
```yaml
# use-role.yml
---
- hosts: web
  tasks:
    - name: Import and run my-role
      import_role:
        name: my-role
```

**With variable overrides:**
```yaml
# use-role-with-vars.yml
---
- hosts: web
  roles:
    - role: my-role
      vars:
        web_message: "Custom Message Override!"
        web_root: /tmp/custom_web
```

### Example 3: Complete NGINX Role

```yaml
# roles/nginx/defaults/main.yml
---
nginx_port: 80
nginx_server_name: localhost
nginx_root: /var/www/html
nginx_index: index.html
nginx_worker_processes: auto
nginx_worker_connections: 1024

# roles/nginx/tasks/main.yml
---
- name: Install nginx
  package:
    name: nginx
    state: present

- name: Create web root
  file:
    path: "{{ nginx_root }}"
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: reload nginx

- name: Configure default site
  template:
    src: default.conf.j2
    dest: /etc/nginx/sites-available/default
  notify: reload nginx

- name: Enable default site
  file:
    src: /etc/nginx/sites-available/default
    dest: /etc/nginx/sites-enabled/default
    state: link
  notify: reload nginx

- name: Ensure nginx is running
  service:
    name: nginx
    state: started
    enabled: yes

# roles/nginx/handlers/main.yml
---
- name: reload nginx
  service:
    name: nginx
    state: reloaded

- name: restart nginx
  service:
    name: nginx
    state: restarted

# roles/nginx/templates/nginx.conf.j2
worker_processes {{ nginx_worker_processes }};

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile on;
    keepalive_timeout 65;

    include /etc/nginx/sites-enabled/*;
}
```

---

## Best Practices

### 1. Use Sensible Defaults

```yaml
# defaults/main.yml - Provide working defaults
nginx_port: 80
nginx_ssl_enabled: false
nginx_log_level: warn
```

### 2. Document Your Role

```markdown
# roles/nginx/README.md

# Nginx Role

Installs and configures nginx web server.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| nginx_port | 80 | HTTP listen port |
| nginx_ssl_enabled | false | Enable SSL |

## Example

```yaml
- hosts: webservers
  roles:
    - role: nginx
      vars:
        nginx_port: 8080
```
```

### 3. Use Tags for Flexibility

```yaml
# tasks/main.yml
- name: Install packages
  package:
    name: "{{ item }}"
    state: present
  loop: "{{ packages }}"
  tags:
    - install
    - packages

- name: Configure service
  template:
    src: config.j2
    dest: /etc/app/config.yml
  tags:
    - configure
```

### 4. Keep Roles Focused

```
# Good: Single responsibility
roles/
├── nginx/           # Only nginx
├── php/             # Only PHP
└── mysql/           # Only MySQL

# Bad: Too broad
roles/
└── lamp/           # Everything combined
```

### 5. Test Your Roles

```yaml
# roles/nginx/tests/test.yml
---
- hosts: localhost
  roles:
    - nginx

  tasks:
    - name: Verify nginx is running
      shell: "pgrep nginx"
      changed_when: false

    - name: Verify nginx responds
      uri:
        url: "http://localhost:{{ nginx_port }}"
        status_code: 200
```

---

## Summary

In this section, you learned:

1. **What roles are**: Reusable, organized automation content
2. **Directory structure**: defaults, vars, tasks, handlers, files, templates
3. **Creating roles**: Using `ansible-galaxy init`
4. **Using roles**: `roles:`, `import_role`, `include_role`
5. **Variables**: defaults vs vars, precedence
6. **Dependencies**: Role dependencies in meta/main.yml
7. **Best practices**: Documentation, defaults, testing

---

## Next Steps

Continue to [Section 11: Tags](./SECTION_11.md) to learn about selective task execution.

---

## Quick Reference

```bash
# Create new role
ansible-galaxy role init rolename

# Role paths in ansible.cfg
roles_path = ./roles:/etc/ansible/roles
```

```yaml
# Use role in playbook
roles:
  - common
  - role: nginx
    vars:
      nginx_port: 8080

# Import role in tasks
- import_role:
    name: nginx

# Include role dynamically
- include_role:
    name: "{{ my_role }}"
```
