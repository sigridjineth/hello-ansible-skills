# Section 12: Ansible Galaxy & Collections

## Table of Contents
- [What is Ansible Galaxy?](#what-is-ansible-galaxy)
- [Roles vs Collections](#roles-vs-collections)
- [Using Ansible Galaxy](#using-ansible-galaxy)
- [Installing Content](#installing-content)
- [Creating a Requirements File](#creating-a-requirements-file)
- [Using Collections](#using-collections)
- [FQCN - Fully Qualified Collection Names](#fqcn---fully-qualified-collection-names)
- [Practical Examples](#practical-examples)

---

## What is Ansible Galaxy?

**Ansible Galaxy** is a community hub for sharing Ansible content.

### Galaxy Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      ANSIBLE GALAXY                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   https://galaxy.ansible.com                                    │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                                                          │  │
│   │    ┌────────────┐        ┌────────────────────────┐    │  │
│   │    │   ROLES    │        │     COLLECTIONS        │    │  │
│   │    ├────────────┤        ├────────────────────────┤    │  │
│   │    │ geerlingguy│        │ community.general      │    │  │
│   │    │ .docker    │        │ community.aws          │    │  │
│   │    │            │        │ ansible.posix          │    │  │
│   │    │ geerlingguy│        │ kubernetes.core        │    │  │
│   │    │ .nginx     │        │ amazon.aws             │    │  │
│   │    │            │        │ azure.azcollection     │    │  │
│   │    │ ...1000s   │        │ google.cloud           │    │  │
│   │    │ more...    │        │ ...100s more...        │    │  │
│   │    └────────────┘        └────────────────────────┘    │  │
│   │                                                          │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│   Your Playbook                                                 │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │ - hosts: all                                             │  │
│   │   roles:                                                 │  │
│   │     - geerlingguy.docker    ← From Galaxy              │  │
│   │   tasks:                                                 │  │
│   │     - community.general.archive:  ← From Collection    │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### What You Can Find

| Content Type | Description | Example |
|--------------|-------------|---------|
| **Roles** | Reusable task bundles | `geerlingguy.nginx` |
| **Collections** | Bundles of modules, plugins, roles | `community.general` |
| **Modules** | Individual task types | `community.general.archive` |
| **Plugins** | Filters, lookups, callbacks | `community.general.json_query` |

---

## Roles vs Collections

### Traditional Roles

```
role/
├── tasks/main.yml       # Tasks only
├── handlers/main.yml
├── defaults/main.yml
├── vars/main.yml
├── files/
└── templates/
```

- Single purpose (e.g., "install nginx")
- Contains tasks, handlers, variables, templates
- Installed per-project or globally

### Modern Collections

```
collection/
├── plugins/
│   ├── modules/         # Multiple modules
│   ├── filters/         # Custom filters
│   ├── lookups/         # Lookup plugins
│   └── callback/        # Callback plugins
├── roles/               # Can include roles too!
├── playbooks/           # Example playbooks
└── docs/                # Documentation
```

- Multi-purpose package
- Contains modules, plugins, AND roles
- Namespaced: `namespace.collection`

### When to Use Each

| Use Case | Recommendation |
|----------|----------------|
| Single application setup | Role |
| Multiple related tools | Collection |
| New modules/plugins | Collection |
| Simple task reuse | Role |
| Cloud provider integration | Collection |

---

## Using Ansible Galaxy

### Search for Content

```bash
# Search for roles
$ ansible-galaxy search nginx
Found 772 roles matching your search:

 Name                           Description
 ----                           -----------
 geerlingguy.nginx              Nginx installation for Linux
 jdauphant.nginx                Nginx role with config management
 ...

# Search with filters
$ ansible-galaxy search nginx --platforms Ubuntu
$ ansible-galaxy search nginx --galaxy-tags web
```

### Get Role Information

```bash
# View role details
$ ansible-galaxy info geerlingguy.nginx

Role: geerlingguy.nginx
    description: Nginx installation for Linux
    active: True
    company: Midwestern Mac
    download_count: 15000000+
    github_repo: ansible-role-nginx
    github_user: geerlingguy
    min_ansible_version: 2.4
    platforms: ...
```

### List Installed Content

```bash
# List installed roles
$ ansible-galaxy role list
# - geerlingguy.docker, 6.1.0
# - geerlingguy.nginx, 3.1.0

# List installed collections
$ ansible-galaxy collection list
Collection               Version
------------------------ -------
community.general        12.2.0
ansible.posix            1.6.2
amazon.aws               9.1.1
...
```

---

## Installing Content

### Install Roles

```bash
# Install from Galaxy
$ ansible-galaxy role install geerlingguy.nginx
- downloading role 'nginx', owned by geerlingguy
- extracting geerlingguy.nginx to /Users/user/.ansible/roles/geerlingguy.nginx
- geerlingguy.nginx was installed successfully

# Install specific version
$ ansible-galaxy role install geerlingguy.nginx,3.1.0

# Install to custom path
$ ansible-galaxy role install geerlingguy.nginx -p ./roles/

# Install from GitHub
$ ansible-galaxy role install git+https://github.com/user/repo.git

# Install from file
$ ansible-galaxy role install -r requirements.yml
```

### Install Collections

```bash
# Install from Galaxy
$ ansible-galaxy collection install community.general
Starting galaxy collection install process
Installing 'community.general:12.2.0' to '/Users/user/.ansible/collections'
community.general:12.2.0 was installed successfully

# Install specific version
$ ansible-galaxy collection install community.general:12.0.0

# Install to custom path
$ ansible-galaxy collection install community.general -p ./collections/

# Install from file
$ ansible-galaxy collection install -r requirements.yml
```

### Installation Locations

| Type | Default Location |
|------|-----------------|
| Roles (user) | `~/.ansible/roles/` |
| Roles (project) | `./roles/` |
| Collections (user) | `~/.ansible/collections/` |
| Collections (project) | `./collections/` |

---

## Creating a Requirements File

### requirements.yml Structure

```yaml
# requirements.yml
---
# Roles section
roles:
  # From Galaxy
  - name: geerlingguy.docker
    version: "7.4.0"

  # From GitHub
  - src: https://github.com/user/ansible-role-example
    name: my-custom-role
    version: main

  # From Git with specific ref
  - src: git@github.com:user/private-role.git
    scm: git
    version: v1.0.0

# Collections section
collections:
  # From Galaxy
  - name: community.general
    version: ">=12.0.0"

  - name: ansible.posix
    version: ">=1.5.0"

  - name: amazon.aws
    version: "9.1.1"

  # From URL
  - name: https://example.com/my_namespace-my_collection-1.0.0.tar.gz
```

### Install from Requirements

```bash
# Install both roles and collections
$ ansible-galaxy install -r requirements.yml

# Install roles only
$ ansible-galaxy role install -r requirements.yml

# Install collections only
$ ansible-galaxy collection install -r requirements.yml

# Force reinstall
$ ansible-galaxy install -r requirements.yml --force
```

---

## Using Collections

### Collection Modules in Playbooks

```yaml
---
- hosts: all
  tasks:
    # Using FQCN (Fully Qualified Collection Name)
    - name: Create archive
      community.general.archive:
        path: /tmp/data
        dest: /tmp/backup.tar.gz
        format: gz

    # Using collection from amazon.aws
    - name: Create EC2 instance
      amazon.aws.ec2_instance:
        name: "my-instance"
        instance_type: t2.micro
        image_id: ami-123456
```

### Collection Filters and Lookups

```yaml
---
- hosts: all
  vars:
    data:
      users:
        - name: alice
          active: true
        - name: bob
          active: false

  tasks:
    # Using json_query filter from community.general
    - name: Get active users
      debug:
        msg: "{{ data | community.general.json_query('users[?active==`true`].name') }}"
```

### Collection Configuration

In `ansible.cfg`:
```ini
[defaults]
collections_path = ./collections:~/.ansible/collections:/usr/share/ansible/collections
```

---

## FQCN - Fully Qualified Collection Names

### Understanding FQCN

```
┌─────────────────────────────────────────────────────────────────┐
│                    FQCN STRUCTURE                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│    community.general.archive                                    │
│    ─────────┬────────  ──┬───                                   │
│             │            │                                       │
│       ┌─────┴─────┐  ┌───┴───┐                                  │
│       │ namespace │  │module │                                  │
│       │.collection│  │ name  │                                  │
│       └───────────┘  └───────┘                                  │
│                                                                  │
│    Examples:                                                    │
│    ┌────────────────────────────────────────────────────────┐  │
│    │ ansible.builtin.debug      # Built-in debug module     │  │
│    │ ansible.builtin.file       # Built-in file module      │  │
│    │ community.general.archive  # Archive from community    │  │
│    │ community.general.json_query  # Filter (not module)    │  │
│    │ amazon.aws.ec2_instance    # AWS EC2 module            │  │
│    │ kubernetes.core.k8s        # Kubernetes module         │  │
│    └────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Why Use FQCN?

1. **Clarity**: Explicit about which module you're using
2. **Avoid conflicts**: No naming collisions between collections
3. **Future-proof**: Recommended for Ansible 2.10+
4. **Portability**: Works across different Ansible installations

### FQCN Examples

```yaml
---
- hosts: all
  tasks:
    # Built-in modules (ansible.builtin.*)
    - name: Debug message
      ansible.builtin.debug:
        msg: "Using FQCN"

    - name: Copy file
      ansible.builtin.copy:
        src: file.txt
        dest: /tmp/file.txt

    - name: Create directory
      ansible.builtin.file:
        path: /tmp/mydir
        state: directory

    # Community modules
    - name: Create archive
      community.general.archive:
        path: /tmp/mydir
        dest: /tmp/archive.tar.gz

    # Cloud modules
    - name: AWS S3 bucket
      amazon.aws.s3_bucket:
        name: my-bucket
        state: present
```

### Short Names (Still Work)

```yaml
# These still work but FQCN is recommended
- name: Old style
  debug:          # Equivalent to ansible.builtin.debug
    msg: "Hello"

- name: FQCN style (recommended)
  ansible.builtin.debug:
    msg: "Hello"
```

---

## Practical Examples

### Example 1: Using Collections (From Lab)

```yaml
# collection-example.yml
---
- hosts: all
  tasks:
    - name: Create data structure
      ansible.builtin.set_fact:
        my_data:
          users:
            - name: alice
              active: true
            - name: bob
              active: false

    - name: Query using community.general filter
      ansible.builtin.debug:
        msg: "Active users: {{ my_data | community.general.json_query('users[?active==`true`].name') }}"

    - name: Use FQCN explicitly
      ansible.builtin.debug:
        msg: "Using FQCN: ansible.builtin.debug"

    - name: Create archive using community.general
      community.general.archive:
        path: /tmp/web_content
        dest: /tmp/web_backup.tar.gz
        format: gz
      ignore_errors: yes

    - name: Show FQCN pattern
      ansible.builtin.debug:
        msg: "FQCN = namespace.collection.module"
```

### Example 2: Requirements File (From Lab)

```yaml
# requirements.yml
---
collections:
  - name: community.general
    version: ">=12.0.0"
  - name: ansible.posix
    version: ">=1.5.0"

roles:
  - name: geerlingguy.docker
    version: "7.4.0"
```

### Example 3: Project with Dependencies

**Project Structure:**
```
project/
├── ansible.cfg
├── inventory
├── requirements.yml
├── collections/          # Local collections
├── roles/               # Local roles
└── playbooks/
    └── site.yml
```

**ansible.cfg:**
```ini
[defaults]
inventory = ./inventory
roles_path = ./roles:~/.ansible/roles
collections_path = ./collections:~/.ansible/collections
```

**Install and run:**
```bash
# Install dependencies
ansible-galaxy install -r requirements.yml

# Run playbook
ansible-playbook playbooks/site.yml
```

### Example 4: Multi-Cloud Playbook

```yaml
---
- hosts: localhost
  collections:
    - amazon.aws
    - azure.azcollection
    - google.cloud

  tasks:
    - name: AWS - Create S3 bucket
      amazon.aws.s3_bucket:
        name: my-bucket
        state: present
      when: cloud_provider == 'aws'

    - name: Azure - Create storage account
      azure.azcollection.azure_rm_storageaccount:
        resource_group: myResourceGroup
        name: mystorageaccount
        account_type: Standard_LRS
      when: cloud_provider == 'azure'

    - name: GCP - Create storage bucket
      google.cloud.gcp_storage_bucket:
        name: my-gcp-bucket
        project: my-project
      when: cloud_provider == 'gcp'
```

---

## Summary

In this section, you learned:

1. **Ansible Galaxy**: Community hub for roles and collections
2. **Roles vs Collections**: When to use each
3. **Installing content**: `ansible-galaxy install`
4. **Requirements files**: Managing dependencies
5. **Using collections**: In playbooks and tasks
6. **FQCN**: Fully Qualified Collection Names

---

## Quick Reference

```bash
# Search
ansible-galaxy search nginx
ansible-galaxy role info geerlingguy.nginx

# Install
ansible-galaxy role install geerlingguy.nginx
ansible-galaxy collection install community.general
ansible-galaxy install -r requirements.yml

# List
ansible-galaxy role list
ansible-galaxy collection list
```

```yaml
# requirements.yml
collections:
  - name: community.general
    version: ">=12.0.0"

roles:
  - name: geerlingguy.docker
    version: "7.4.0"
```

```yaml
# Using FQCN in playbooks
- ansible.builtin.debug:
    msg: "Built-in module"

- community.general.archive:
    path: /tmp/data
    dest: /tmp/backup.tar.gz
```

---

## Conclusion

Congratulations! You have completed the Ansible tutorial covering:

1. **Basics**: Installation, inventory, configuration
2. **Playbooks**: Tasks, plays, YAML syntax
3. **Variables**: Types, precedence, registration
4. **Facts**: System information gathering
5. **Loops**: Iterating over data
6. **Conditionals**: Selective execution
7. **Handlers**: Triggered tasks
8. **Error Handling**: Managing failures
9. **Roles**: Reusable automation
10. **Tags**: Selective running
11. **Galaxy**: Sharing and reusing content

Continue learning by:
- Exploring Ansible Galaxy for roles
- Writing your own roles
- Automating your infrastructure
- Contributing to the Ansible community!
