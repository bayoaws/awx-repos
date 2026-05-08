# ==============================================================================
# AAP 2.4 Configuration Guide — Proxmox Automation
# Configure Controller UI at: https://ctrl.technexus.com
# ==============================================================================


# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — GITHUB REPOSITORY SETUP
# ══════════════════════════════════════════════════════════════════════════════

# 1.1 Create repo on GitHub.com
#     Name        : proxmox-automation
#     Visibility  : Private (recommended)
#     Init        : Yes (add README)

# 1.2 Push your local project to GitHub from ctrl
cd ~/proxmox-automation
git init
git add .
git commit -m "Initial commit — Proxmox automation roles and playbooks"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/proxmox-automation.git
git push -u origin main

# 1.3 Create a GitHub Personal Access Token (PAT) for AAP
#     GitHub → Settings → Developer Settings → Personal Access Tokens → Fine-grained
#     Repository access : Only select proxmox-automation
#     Permissions       : Contents = Read-only
#     Save the token — you'll paste it into AAP


# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — AAP CREDENTIALS
# https://ctrl.technexus.com → Resources → Credentials
# ══════════════════════════════════════════════════════════════════════════════

# ── 2.1 GitHub Credential ─────────────────────────────────────────────────
# Resources → Credentials → Add
Name            : GitHub - proxmox-automation
Credential Type : Source Control
Username        : your-github-username
Password/Token  : <your PAT token from step 1.3>

# ── 2.2 Machine Credential (ansible_aap SSH key) ──────────────────────────
# Resources → Credentials → Add
Name            : TechNexus Lab - ansible_aap
Credential Type : Machine
Username        : ansible_aap
SSH Private Key : <paste contents of /home/ansible_aap/.ssh/id_ed25519>
Privilege Escalation Method : sudo

# To get the private key:
# cat /home/ansible_aap/.ssh/id_ed25519

# ── 2.3 Proxmox Custom Credential Type ───────────────────────────────────
# Administration → Credential Types → Add
Name        : Proxmox API
Description : Proxmox VE API token authentication

# INPUT CONFIGURATION:
fields:
  - id: proxmox_host
    type: string
    label: Proxmox Host
  - id: proxmox_port
    type: string
    label: Proxmox Port
  - id: proxmox_user
    type: string
    label: API User (user@realm)
  - id: proxmox_token_id
    type: string
    label: Token ID
  - id: proxmox_token_secret
    type: string
    label: Token Secret
    secret: true
  - id: proxmox_node
    type: string
    label: Node Name
required:
  - proxmox_host
  - proxmox_user
  - proxmox_token_id
  - proxmox_token_secret
  - proxmox_node

# INJECTOR CONFIGURATION:
extra_vars:
  proxmox_host: "{{ proxmox_host }}"
  proxmox_port: "{{ proxmox_port | default('8006') }}"
  proxmox_user: "{{ proxmox_user }}"
  proxmox_token_id: "{{ proxmox_token_id }}"
  proxmox_token_secret: "{{ proxmox_token_secret }}"
  proxmox_node: "{{ proxmox_node }}"

# ── 2.4 Create Proxmox Credential using the new type ─────────────────────
# Resources → Credentials → Add
Name            : Proxmox TechNexus
Credential Type : Proxmox API
Proxmox Host    : 192.168.4.50
Proxmox Port    : 8006
API User        : ansible_aap@pve
Token ID        : ansible-token
Token Secret    : 37823db2-ac5f-498d-bfda-8379d8347594
Node Name       : technexus


# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — PROJECT (Git Sync)
# Resources → Projects → Add
# ══════════════════════════════════════════════════════════════════════════════

Name                : Proxmox Automation
Organization        : Default
Source Control Type : Git
Source Control URL  : https://github.com/YOUR_USERNAME/proxmox-automation.git
Source Control Branch: main
Credential          : GitHub - proxmox-automation
Options:
  ✅ Clean
  ✅ Update Revision on Launch
  ✅ Allow Branch Override

# Click SAVE → Click SYNC PROJECT → Wait for green status


# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — INVENTORIES
# Resources → Inventories
# ══════════════════════════════════════════════════════════════════════════════

# ── 4.1 Lab Static Inventory ──────────────────────────────────────────────
# Resources → Inventories → Add → Inventory
Name         : TechNexus Lab
Organization : Default
# After saving → Sources → Add
# Add hosts manually or via inventory file:
#   Hosts → Add each host with vars:
#   ctrl.technexus.com  ansible_host=192.168.4.102
#   exec1.technexus.com ansible_host=192.168.4.103
#   ... etc

# ── 4.2 Proxmox Dynamic Inventory ────────────────────────────────────────
# Resources → Inventories → Add → Inventory
Name         : Proxmox Dynamic
Organization : Default
# After saving → Sources → Add → Source
Name          : Proxmox VE
Source        : Sourced from a Project
Project       : Proxmox Automation
Inventory File: inventory/proxmox.yml
Credential    : Proxmox TechNexus
Options:
  ✅ Overwrite
  ✅ Update on Launch

# ── 4.3 Localhost Inventory ───────────────────────────────────────────────
# Resources → Inventories → Add → Inventory
Name         : Localhost
Organization : Default
# After saving → Hosts → Add
# Host Name: localhost
# Variables:
ansible_connection: local
ansible_python_interpreter: /usr/bin/python3


# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — JOB TEMPLATES
# Resources → Templates → Add → Job Template
# ══════════════════════════════════════════════════════════════════════════════

# ── JT 1: Create VM ───────────────────────────────────────────────────────
Name        : Proxmox - Create VM
Job Type    : Run
Inventory   : Localhost
Project     : Proxmox Automation
Playbook    : playbooks/vm_create.yml
Credentials :
  - Proxmox TechNexus
Verbosity   : 1 (Changed)
Enable Survey: YES

Survey:
  Q1: VM ID (VMID)
      variable: vm_id
      type: Integer | required | min: 100 max: 999

  Q2: VM Name
      variable: vm_name
      type: Text | required
      hint: Short hostname e.g. testserver01

  Q3: Memory (MB)
      variable: vm_memory
      type: Multiple Choice (Single)
      choices: 2048 | 4096 | 8192 | 16384
      default: 4096

  Q4: CPU Cores
      variable: vm_cpu
      type: Multiple Choice (Single)
      choices: 1 | 2 | 4 | 8
      default: 2

  Q5: Disk Size (GB)
      variable: vm_disk_size
      type: Multiple Choice (Single)
      choices: 20 | 50 | 100 | 200
      default: 50

  Q6: ISO Image
      variable: vm_iso
      type: Multiple Choice (Single)
      choices:
        local:iso/Rocky-9.5-x86_64-dvd.iso
        local:iso/AlmaLinux-8.9-x86_64-dvd.iso
        local:iso/rhel-9.3-x86_64-dvd.iso
      default: local:iso/Rocky-9.5-x86_64-dvd.iso

  Q7: Tags
      variable: vm_tags
      type: Text | not required
      default: lab


# ── JT 2: Configure VM ────────────────────────────────────────────────────
Name        : Proxmox - Configure VM
Job Type    : Run
Inventory   : Proxmox Dynamic  (or TechNexus Lab)
Project     : Proxmox Automation
Playbook    : playbooks/vm_configure.yml
Credentials :
  - TechNexus Lab - ansible_aap
Verbosity   : 1 (Changed)
Enable Survey: YES

Survey:
  Q1: Target Host IP
      variable: target_host
      type: Text | required
      hint: IP address of the VM to configure

  Q2: VM FQDN
      variable: vm_fqdn
      type: Text | required
      hint: e.g. testserver01.technexus.com

  Q3: VM Short Name
      variable: vm_name
      type: Text | required

  Q4: IP Address
      variable: vm_ip
      type: Text | required

  Q5: Default Gateway
      variable: vm_gateway
      type: Text | not required
      default: 192.168.4.1


# ── JT 3: Snapshot VMs ────────────────────────────────────────────────────
Name        : Proxmox - Snapshot VMs
Job Type    : Run
Inventory   : Localhost
Project     : Proxmox Automation
Playbook    : playbooks/vm_snapshot.yml
Credentials :
  - Proxmox TechNexus
Enable Survey: YES

Survey:
  Q1: Snapshot Name
      variable: snapshot_name
      type: Text | required
      hint: e.g. before_upgrade_20260507

  Q2: Action
      variable: snapshot_state
      type: Multiple Choice (Single)
      choices: present | absent
      default: present

  Q3: Include RAM State
      variable: snapshot_include_ram
      type: Multiple Choice (Single)
      choices: false | true
      default: false


# ── JT 4: Power Management ────────────────────────────────────────────────
Name        : Proxmox - Power Management
Job Type    : Run
Inventory   : Localhost
Project     : Proxmox Automation
Playbook    : playbooks/vm_power.yml
Credentials :
  - Proxmox TechNexus
Enable Survey: YES

Survey:
  Q1: Power Action
      variable: vm_power_state
      type: Multiple Choice (Single)
      choices: started | stopped | restarted
      required: YES

  Q2: Force Stop (bypass graceful shutdown)
      variable: vm_force_stop
      type: Multiple Choice (Single)
      choices: false | true
      default: false


# ── JT 5: Delete VM ───────────────────────────────────────────────────────
Name        : Proxmox - Delete VM
Job Type    : Run
Inventory   : Localhost
Project     : Proxmox Automation
Playbook    : playbooks/vm_delete.yml
Credentials :
  - Proxmox TechNexus
Verbosity   : 1 (Changed)
Enable Survey: YES

Survey:
  Q1: VM ID to Delete
      variable: vm_id
      type: Integer | required

  Q2: Confirm VM Name (safety check)
      variable: vm_name_confirm
      type: Text | required
      hint: Must exactly match the VM name in Proxmox


# ══════════════════════════════════════════════════════════════════════════════
# STEP 6 — GITHUB WEBHOOK (auto-sync on git push)
# ══════════════════════════════════════════════════════════════════════════════

# 6.1 Get webhook URL from AAP
#     Resources → Projects → Proxmox Automation → Edit
#     Copy the "Webhook URL" shown at the bottom

# 6.2 Create webhook on GitHub
#     GitHub → proxmox-automation repo → Settings → Webhooks → Add webhook
#     Payload URL  : https://ctrl.technexus.com/api/v2/projects/YOUR_PROJECT_ID/update/
#     Content type : application/json
#     Secret       : leave empty (or set and add to AAP webhook credential)
#     Events       : Just the push event
#     Active       : ✅

# 6.3 Test it
#     Make any change to a file, git commit + push
#     AAP Project should auto-sync within seconds


# ══════════════════════════════════════════════════════════════════════════════
# STEP 7 — END-TO-END TEST
# ══════════════════════════════════════════════════════════════════════════════

# 1. Push latest code to GitHub
#    git add . && git commit -m "Add roles" && git push

# 2. AAP auto-syncs project (or click Sync manually)

# 3. Launch "Proxmox - Create VM" Job Template
#    Fill in survey: VMID=130, Name=testvm-aap, RAM=4096, etc.
#    Click LAUNCH

# 4. Watch the job run in AAP UI — real-time output

# 5. Verify in Proxmox UI → VM 130 created and running

# 6. Complete OS install via Proxmox console

# 7. Launch "Proxmox - Configure VM" Job Template
#    Fill in survey: IP, FQDN, hostname
#    Click LAUNCH

# 8. VM fully configured and reachable via SSH as ansible_aap ✔
