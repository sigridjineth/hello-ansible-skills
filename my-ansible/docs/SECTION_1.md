# Section 1: Introduction to Ansible & Lab Setup

## Table of Contents
- [What is Ansible?](#what-is-ansible)
- [Key Concepts](#key-concepts)
- [Architecture Overview](#architecture-overview)
- [Why Ansible?](#why-ansible)
- [Lab Environment Setup](#lab-environment-setup)
- [Prerequisites](#prerequisites)
- [Verification](#verification)

---

## What is Ansible?

Ansible is an **open-source automation tool** developed by Red Hat that simplifies:
- **Configuration Management**: Ensure systems are in a desired state
- **Application Deployment**: Deploy applications consistently across environments
- **Task Automation**: Automate repetitive IT tasks
- **Orchestration**: Coordinate multi-tier deployments

### The Name "Ansible"
The name comes from science fiction - an "ansible" is a fictional faster-than-light communication device. In IT, Ansible communicates with many servers simultaneously, making the name fitting.

---

## Key Concepts

### 1. Agentless Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      ANSIBLE ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│    ┌──────────────────┐                                         │
│    │   Control Node   │                                         │
│    │  (Your Machine)  │                                         │
│    │                  │                                         │
│    │  - Ansible CLI   │                                         │
│    │  - Playbooks     │                                         │
│    │  - Inventory     │                                         │
│    └────────┬─────────┘                                         │
│             │                                                    │
│             │ SSH (Linux/macOS) or WinRM (Windows)              │
│             │ NO AGENT REQUIRED ON MANAGED NODES                │
│             │                                                    │
│    ┌────────┴────────┬─────────────────┬─────────────────┐     │
│    ▼                 ▼                 ▼                 ▼     │
│ ┌──────┐        ┌──────┐         ┌──────┐         ┌──────┐    │
│ │ Web1 │        │ Web2 │         │ DB1  │         │ DB2  │    │
│ │Server│        │Server│         │Server│         │Server│    │
│ └──────┘        └──────┘         └──────┘         └──────┘    │
│                                                                  │
│  Managed Nodes - Only need SSH/Python (Linux) or WinRM (Win)   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- **No agents to install** on managed nodes
- Uses **SSH** for Linux/Unix or **WinRM** for Windows
- Only requires **Python** on managed nodes (usually pre-installed)
- **Push-based**: Control node pushes configurations to managed nodes

### 2. Core Components

| Component | Description | Example |
|-----------|-------------|---------|
| **Control Node** | Machine where Ansible is installed | Your laptop, CI/CD server |
| **Managed Nodes** | Target machines Ansible manages | Web servers, databases |
| **Inventory** | List of managed nodes | `inventory` file |
| **Modules** | Units of code Ansible executes | `apt`, `yum`, `copy`, `file` |
| **Playbooks** | YAML files defining automation | `deploy.yml` |
| **Roles** | Reusable playbook organization | `roles/webserver/` |
| **Tasks** | Individual actions in playbooks | "Install nginx" |

### 3. Idempotency

**Idempotency** means running the same operation multiple times produces the same result:

```
First Run:
  "Install nginx" → nginx gets installed → CHANGED

Second Run:
  "Install nginx" → nginx already installed → OK (no change)

Third Run:
  "Install nginx" → nginx already installed → OK (no change)
```

This is **crucial** because:
- Safe to run playbooks multiple times
- No unintended side effects
- Ensures consistent state

---

## Architecture Overview

### How Ansible Executes Tasks

```
┌─────────────────────────────────────────────────────────────────┐
│                    ANSIBLE EXECUTION FLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. READ PLAYBOOK                                               │
│     ┌─────────────┐                                             │
│     │ playbook.yml│ ──→ Parse YAML                              │
│     └─────────────┘                                             │
│            │                                                     │
│            ▼                                                     │
│  2. READ INVENTORY                                              │
│     ┌─────────────┐                                             │
│     │  inventory  │ ──→ Identify target hosts                   │
│     └─────────────┘                                             │
│            │                                                     │
│            ▼                                                     │
│  3. GATHER FACTS (optional)                                     │
│     ┌─────────────┐                                             │
│     │ setup module│ ──→ Collect system info from targets        │
│     └─────────────┘                                             │
│            │                                                     │
│            ▼                                                     │
│  4. EXECUTE TASKS                                               │
│     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐    │
│     │   Task 1    │ ──→ │   Task 2    │ ──→ │   Task N    │    │
│     └─────────────┘     └─────────────┘     └─────────────┘    │
│            │                                                     │
│            ▼                                                     │
│  5. REPORT RESULTS                                              │
│     ┌─────────────────────────────────────────────────────┐    │
│     │ PLAY RECAP                                           │    │
│     │ server1: ok=3 changed=1 unreachable=0 failed=0      │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Why Ansible?

### Comparison with Other Tools

| Feature | Ansible | Puppet | Chef | SaltStack |
|---------|---------|--------|------|-----------|
| **Architecture** | Agentless | Agent-based | Agent-based | Agent/Agentless |
| **Language** | YAML | Puppet DSL | Ruby | YAML/Python |
| **Learning Curve** | Low | Medium | High | Medium |
| **Push/Pull** | Push | Pull | Pull | Both |
| **Windows Support** | Good | Good | Good | Good |

### Ansible Advantages

1. **Simple YAML Syntax**
   ```yaml
   # Human-readable, no programming required
   - name: Install nginx
     apt:
       name: nginx
       state: present
   ```

2. **No Infrastructure Required**
   - No master servers to maintain
   - No databases to manage
   - No agents to update

3. **Extensive Module Library**
   - 3,000+ built-in modules
   - Cloud providers (AWS, Azure, GCP)
   - Network devices (Cisco, Juniper)
   - Containers (Docker, Kubernetes)

4. **Large Community**
   - Ansible Galaxy for shared roles
   - Active development by Red Hat
   - Extensive documentation

---

## Lab Environment Setup

### Option A: VM-based Lab (x86 Architecture)

For traditional x86 machines, you can use Vagrant + VirtualBox:

```bash
# Install prerequisites
brew install vagrant virtualbox ansible

# Create Vagrantfile
cat > Vagrantfile << 'EOF'
Vagrant.configure("2") do |config|
  # Control Node
  config.vm.define "ansible-server" do |server|
    server.vm.box = "ubuntu/focal64"
    server.vm.hostname = "ansible-server"
    server.vm.network "private_network", ip: "192.168.56.10"
  end

  # Managed Nodes
  (1..3).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "ubuntu/focal64"
      node.vm.hostname = "node#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{10+i}"
    end
  end
end
EOF

vagrant up
```

### Option B: Local Lab (ARM64/Apple Silicon) - **Used in This Tutorial**

For Apple Silicon Macs or when VMs aren't practical:

```bash
# Create project directory
mkdir -p ~/ansible-lab/my-ansible
cd ~/ansible-lab/my-ansible

# Verify Ansible installation
ansible --version
```

**Why Local Lab?**
- Works on any architecture (ARM64, x86)
- No VM overhead
- Faster iteration for learning
- Uses `ansible_connection=local`

---

## Prerequisites

### Required Software

| Software | Purpose | Installation |
|----------|---------|--------------|
| **Ansible** | Automation tool | `brew install ansible` |
| **Python 3** | Required by Ansible | Usually pre-installed |
| **Text Editor** | Edit YAML files | VS Code, Vim, etc. |

### Verify Installation

```bash
# Check Ansible version
$ ansible --version
ansible [core 2.18.2]
  config file = None
  configured module search path = ['/Users/user/.ansible/plugins/modules']
  ansible python module location = /opt/homebrew/lib/python3.13/site-packages/ansible
  ansible collection location = /Users/user/.ansible/collections
  executable location = /opt/homebrew/bin/ansible
  python version = 3.13.1
  jinja version = 3.1.5
  libyaml = True

# Check Python
$ python3 --version
Python 3.13.1

# Verify Ansible can run
$ ansible localhost -m ping
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## Verification

### Test Your Setup

Run these commands to verify everything works:

```bash
# 1. Create test directory
mkdir -p ~/ansible-lab/my-ansible
cd ~/ansible-lab/my-ansible

# 2. Create minimal inventory
echo "localhost ansible_connection=local" > inventory

# 3. Test connectivity
ansible -i inventory localhost -m ping

# Expected output:
# localhost | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }

# 4. Test a simple command
ansible -i inventory localhost -m shell -a "echo 'Ansible is working!'"

# Expected output:
# localhost | CHANGED | rc=0 >>
# Ansible is working!
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `ansible: command not found` | Install Ansible: `brew install ansible` |
| Python errors | Ensure Python 3 is installed |
| Permission denied | Check SSH keys or use `ansible_connection=local` |
| Module not found | Update Ansible: `brew upgrade ansible` |

---

## Summary

In this section, you learned:

1. **What Ansible is**: An agentless automation tool
2. **Key concepts**: Control nodes, managed nodes, idempotency
3. **Architecture**: Push-based, SSH/WinRM communication
4. **Why Ansible**: Simple YAML, no agents, extensive modules
5. **Lab setup**: Local environment for learning

---

## Next Steps

Continue to [Section 2: Inventory & Configuration](./SECTION_2.md) to learn how to define your infrastructure in Ansible.

---

## Quick Reference

```bash
# Essential commands learned
ansible --version          # Check Ansible version
ansible localhost -m ping  # Test connectivity
```
