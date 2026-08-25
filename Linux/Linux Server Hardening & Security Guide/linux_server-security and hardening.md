# Linux Server Hardening & Security Guide

A practical, step-by-step checklist for hardening a Linux server (Ubuntu/Debian commands shown; RHEL/CentOS equivalents noted where they differ).

> ⚠️ **Before you start:** Always keep an active SSH session open while making SSH/firewall changes, and test new connections from a *second* terminal before closing the first. This prevents accidental lockouts.

---

## Table of Contents

1. [System Updates](#1-system-updates)
2. [User & Group Management](#2-user--group-management)
3. [Sudo Configuration](#3-sudo-configuration)
4. [SSH Hardening](#4-ssh-hardening)
5. [SSH Key Authentication](#5-ssh-key-authentication)
6. [Disabling Root Login](#6-disabling-root-login)
7. [File Permissions & Ownership](#7-file-permissions--ownership)
8. [Firewall (UFW)](#8-firewall-ufw)
9. [Checking Open Ports](#9-checking-open-ports)
10. [Service Management](#10-service-management)
11. [Fail2ban](#11-fail2ban)
12. [Automatic Security Updates](#12-automatic-security-updates)
13. [Audit & Log Review](#13-audit--log-review)
14. [Final Verification Checklist](#14-final-verification-checklist)

---

## 1. System Updates

Keep the system patched first — most exploits target known, unpatched vulnerabilities.

```bash
sudo apt update && sudo apt upgrade -y      # Debian/Ubuntu
sudo dnf update -y                          # RHEL/CentOS/Fedora
```

Reboot if a kernel update was installed:

```bash
sudo reboot
```

---

## 2. User & Group Management

**List users and groups:**

```bash
cat /etc/passwd          # all users
cat /etc/group           # all groups
awk -F: '$3 >= 1000 {print $1}' /etc/passwd   # non-system (human) users
```

**Create a new user (non-root, for daily admin work):**

```bash
sudo adduser deployuser
```

**Add user to sudo group:**

```bash
sudo usermod -aG sudo deployuser        # Debian/Ubuntu
sudo usermod -aG wheel deployuser       # RHEL/CentOS
```

**Lock/disable unused or default accounts:**

```bash
sudo passwd -l olduser        # lock password
sudo usermod -s /usr/sbin/nologin olduser   # disable shell login
```

**Enforce password policy** (`/etc/login.defs`):

```
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_WARN_AGE   14
```

Install and configure strong password rules with PAM:

```bash
sudo apt install libpam-pwquality -y
```

Edit `/etc/pam.d/common-password`:

```
password requisite pam_pwquality.so retry=3 minlen=12 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
```

---

## 3. Sudo Configuration

**Never edit `/etc/sudoers` directly** — always use `visudo` (it validates syntax before saving):

```bash
sudo visudo
```

**Give a user full sudo access:**

```
deployuser ALL=(ALL:ALL) ALL
```

**Restrict sudo to specific commands (least privilege):**

```
deployuser ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/apt update
```

**Log all sudo commands:**

Add to `/etc/sudoers` via `visudo`:

```
Defaults log_input,log_output
Defaults logfile="/var/log/sudo.log"
```

**Review sudo log:**

```bash
sudo cat /var/log/sudo.log
sudo journalctl _COMM=sudo
```

---

## 4. SSH Hardening

Edit the SSH daemon config:

```bash
sudo nano /etc/ssh/sshd_config
```

Recommended settings:

```
Port 2222                       # change from default 22 (security by obscurity, not a substitute for other controls)
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers deployuser
LoginGraceTime 30
```

Validate config syntax, then restart:

```bash
sudo sshd -t
sudo systemctl restart sshd
```

> If you change the port, remember to update UFW rules (Section 8) and your SSH client command (`ssh -p 2222 user@host`) **before** disconnecting.

---

## 5. SSH Key Authentication

**On your local machine, generate a key pair:**

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

**Copy the public key to the server:**

```bash
ssh-copy-id -p 2222 deployuser@server_ip
```

Or manually:

```bash
cat ~/.ssh/id_ed25519.pub | ssh -p 2222 deployuser@server_ip \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Set correct permissions on the server:**

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**Test key login, then disable password auth** (`PasswordAuthentication no` in `sshd_config`, already set above).

---

## 6. Disabling Root Login

Confirm root login is off:

```bash
grep -i "PermitRootLogin" /etc/ssh/sshd_config
```

Should return: `PermitRootLogin no`

Set a strong root password anyway (for console/rescue access) and consider locking it entirely if not needed:

```bash
sudo passwd -l root
```

---

## 7. File Permissions & Ownership

**Check ownership and permissions:**

```bash
ls -la /path/to/file
stat /path/to/file
```

**Change ownership:**

```bash
sudo chown user:group /path/to/file
sudo chown -R user:group /path/to/dir
```

**Change permissions:**

```bash
chmod 750 /path/to/dir       # owner: rwx, group: r-x, others: none
chmod 640 /path/to/file      # owner: rw-, group: r--, others: none
```

**Find dangerous world-writable files:**

```bash
sudo find / -xdev -type f -perm -0002 -ls
```

**Find SUID/SGID binaries (potential privilege escalation vectors):**

```bash
sudo find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -ls
```

**Secure sensitive files:**

```bash
sudo chmod 600 /etc/shadow
sudo chmod 644 /etc/passwd
sudo chmod 600 ~/.ssh/id_ed25519
```

---

## 8. Firewall (UFW)

**Install & enable UFW:**

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

**Allow only required services:**

```bash
sudo ufw allow 2222/tcp      # SSH (custom port)
sudo ufw allow 80/tcp        # HTTP
sudo ufw allow 443/tcp       # HTTPS
```

**Enable and check status:**

```bash
sudo ufw enable
sudo ufw status verbose
sudo ufw status numbered
```

**Delete a rule:**

```bash
sudo ufw delete allow 22/tcp
```

**Rate-limit SSH (blocks brute-force attempts hitting the rule repeatedly):**

```bash
sudo ufw limit 2222/tcp
```

---

## 9. Checking Open Ports

**List listening ports and owning processes:**

```bash
sudo ss -tulpn
sudo netstat -tulpn      # if net-tools installed
```

**Scan from outside (from another machine) to verify what's actually reachable:**

```bash
nmap -sT -Pn server_ip
```

Close/disable anything not explicitly required (see Section 10).

---

## 10. Service Management

**List running services:**

```bash
systemctl list-units --type=service --state=running
```

**Disable and stop unnecessary services:**

```bash
sudo systemctl stop servicename
sudo systemctl disable servicename
sudo systemctl mask servicename    # prevents it from being started at all
```

**Common services to review/remove if unused:** `telnet`, `ftp`, `rsh`, `avahi-daemon`, `cups`, `nfs-server`, `rpcbind`.

```bash
sudo apt purge telnetd -y
```

**Check service status:**

```bash
systemctl status servicename
```

---

## 11. Fail2ban

Blocks IPs after repeated failed login attempts.

**Install:**

```bash
sudo apt install fail2ban -y
```

**Configure (copy default before editing so upgrades don't overwrite your changes):**

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Key settings under `[sshd]`:

```ini
[sshd]
enabled = true
port    = 2222
maxretry = 4
bantime  = 3600
findtime = 600
```

**Start and enable:**

```bash
sudo systemctl enable --now fail2ban
```

**Check status and banned IPs:**

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

**Unban an IP:**

```bash
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

---

## 12. Automatic Security Updates

**Ubuntu/Debian:**

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Verify config in `/etc/apt/apt.conf.d/50unattended-upgrades` and `/etc/apt/apt.conf.d/20auto-upgrades`:

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

**RHEL/CentOS:**

```bash
sudo dnf install dnf-automatic -y
sudo systemctl enable --now dnf-automatic.timer
```

---

## 13. Audit & Log Review

**Key log locations:**

| Log | Purpose |
|---|---|
| `/var/log/auth.log` (Debian) / `/var/log/secure` (RHEL) | SSH & auth attempts |
| `/var/log/syslog` | General system log |
| `/var/log/ufw.log` | Firewall activity |
| `/var/log/fail2ban.log` | Ban/unban events |
| `/var/log/sudo.log` | Sudo command history |

**Check failed SSH login attempts:**

```bash
sudo grep "Failed password" /var/log/auth.log
```

**Check successful logins and login history:**

```bash
last -a
lastlog
```

**Check currently logged-in users:**

```bash
who
w
```

**Install auditd for deeper system call auditing:**

```bash
sudo apt install auditd audispd-plugins -y
sudo systemctl enable --now auditd
```

**Add an audit rule (example — watch changes to `/etc/passwd`):**

```bash
sudo auditctl -w /etc/passwd -p wa -k passwd_changes
sudo ausearch -k passwd_changes
```

**Run a rootkit/vulnerability scan periodically:**

```bash
sudo apt install rkhunter lynis -y
sudo rkhunter --check
sudo lynis audit system
```

---

## 14. Final Verification Checklist

- [ ] System fully updated, unattended-upgrades enabled
- [ ] No unused user accounts; strong password policy enforced
- [ ] Sudo access restricted to necessary users, sudo logging enabled
- [ ] SSH: root login disabled, password auth disabled, key-only auth working
- [ ] SSH running on non-default port (optional) and rate-limited
- [ ] Sensitive file permissions locked down (`/etc/shadow`, `~/.ssh`, etc.)
- [ ] No unexpected world-writable or SUID/SGID files
- [ ] UFW enabled with default-deny incoming, only required ports open
- [ ] `ss -tulpn` reviewed — no unexpected listening services
- [ ] Unnecessary services stopped, disabled, and/or masked
- [ ] Fail2ban installed, running, and monitoring SSH jail
- [ ] Logs reviewed for failed logins / suspicious activity
- [ ] auditd + rkhunter/lynis scan run with no critical findings

---

## Quick Reference — Command Cheat Sheet

```bash
# Updates
sudo apt update && sudo apt upgrade -y

# Users
sudo adduser newuser
sudo usermod -aG sudo newuser
sudo passwd -l unusedaccount

# Sudo
sudo visudo

# SSH
sudo nano /etc/ssh/sshd_config
sudo sshd -t && sudo systemctl restart sshd

# Firewall
sudo ufw default deny incoming
sudo ufw allow 2222/tcp
sudo ufw enable
sudo ufw status verbose

# Ports
sudo ss -tulpn

# Services
systemctl list-units --type=service --state=running
sudo systemctl disable --now servicename

# Fail2ban
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd

# Logs
sudo grep "Failed password" /var/log/auth.log
sudo lynis audit system
```

---

## Notes

- Test every change in a **staging/snapshot environment** first if possible.
- Keep a second SSH session open when modifying `sshd_config` or firewall rules.
- Document any deviation from this checklist (e.g., a port left open for a specific service) directly in this file for future reference.
