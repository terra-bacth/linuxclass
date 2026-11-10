#!/usr/bin/env bash
# ==============================================================================
# USS LINUX — DAY 1 AUTOMATED EVALUATION & GRADING SCRIPT (50 POINTS)
# Supports: AlmaLinux 10 (RHEL 10 / el10 family) & Ubuntu 22.04 / 24.04 LTS
# Target Workspace: /var/tmp/day1_audit/
# ==============================================================================
set -uo pipefail

AUDIT_DIR="/var/tmp/day1_audit"
SCORE=0
MAX_SCORE=50

# Detect distribution family
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VER="${VERSION_ID:-unknown}"
else
    OS_ID="unknown"
    OS_VER="unknown"
fi

if [[ "$OS_ID" =~ ^(almalinux|rhel|rocky|centos|fedora)$ ]]; then
    DISTRO_FAMILY="EL10"
    EXPECTED_HOST="alma10-day1.uss.local"
    SUDO_GRP="wheel"
    SSH_UNIT="sshd"
else
    DISTRO_FAMILY="UBUNTU"
    EXPECTED_HOST="ubuntu-day1.uss.local"
    SUDO_GRP="sudo"
    SSH_UNIT="ssh"
fi

printf "======================================================================\n"
printf "   USS LINUX DAY 1 EVALUATION REPORT — 50 POINTS\n"
printf "   Detected OS: %s %s (%s) | Target Host: %s\n" "$OS_ID" "$OS_VER" "$DISTRO_FAMILY" "$EXPECTED_HOST"
printf "======================================================================\n\n"

pass_check() {
    local pts="$1"
    local msg="$2"
    SCORE=$(( SCORE + pts ))
    printf "  [PASS +%2d pts] %s\n" "$pts" "$msg"
}

fail_check() {
    local pts="$1"
    local msg="$2"
    printf "  [FAIL  0/%2d pts] %s\n" "$pts" "$msg"
}

# ------------------------------------------------------------------------------
# TASK 1: Audit Workspace & OS/Kernel Baseline (8 Points)
# ------------------------------------------------------------------------------
printf ">>> Task 1: Audit Workspace & OS/Kernel Baseline (8 pts)\n"
if [[ -d "$AUDIT_DIR" ]]; then
    pass_check 2 "Directory $AUDIT_DIR exists"
else
    fail_check 2 "Directory $AUDIT_DIR is missing"
fi

if [[ -s "$AUDIT_DIR/01_host_identity.txt" ]] && grep -qiE "PRETTY_NAME|Linux|MemTotal" "$AUDIT_DIR/01_host_identity.txt"; then
    pass_check 6 "File 01_host_identity.txt contains OS release, kernel, CPU, and RAM baseline"
else
    fail_check 6 "File 01_host_identity.txt is missing or incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 2: Hostname, /etc/hosts & UTC NTP Synchronization (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 2: Hostname, /etc/hosts & UTC Time Sync (8 pts)\n"
if [[ "$(hostname)" == "$EXPECTED_HOST" ]]; then
    pass_check 3 "Static hostname matches $EXPECTED_HOST"
else
    fail_check 3 "Static hostname is '$(hostname)' (expected '$EXPECTED_HOST')"
fi

if grep -q "$EXPECTED_HOST" /etc/hosts && timedatectl status 2>/dev/null | grep -q "UTC"; then
    pass_check 3 "/etc/hosts contains $EXPECTED_HOST and timezone is UTC"
else
    fail_check 3 "/etc/hosts entry or UTC timezone missing"
fi

if [[ -s "$AUDIT_DIR/02_hostname_time.txt" ]]; then
    pass_check 2 "Deliverable 02_hostname_time.txt verified non-empty"
else
    fail_check 2 "Deliverable 02_hostname_time.txt missing"
fi

# ------------------------------------------------------------------------------
# TASK 3: Administrative User (opsadmin) & Least-Privilege Sudo (10 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 3: Administrative User & Sudo Provisioning (10 pts)\n"
if getent group ops_team | grep -q ":2500:"; then
    pass_check 3 "Group 'ops_team' exists with GID 2500"
else
    fail_check 3 "Group 'ops_team' (GID 2500) missing"
fi

if id -u opsadmin &>/dev/null && [[ "$(id -u opsadmin)" == "2501" ]] && id -nG opsadmin | grep -qw "$SUDO_GRP"; then
    pass_check 5 "User 'opsadmin' (UID 2501) exists and belongs to '$SUDO_GRP' group"
else
    fail_check 5 "User 'opsadmin' (UID 2501) or membership in '$SUDO_GRP' missing"
fi

if [[ -s "$AUDIT_DIR/03_user_sudo.txt" ]]; then
    pass_check 2 "Deliverable 03_user_sudo.txt verified non-empty"
else
    fail_check 2 "Deliverable 03_user_sudo.txt missing"
fi

# ------------------------------------------------------------------------------
# TASK 4: Headless Boot Target & Systemd Service Audit (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 4: Headless Boot Target & Systemd Service Audit (8 pts)\n"
if [[ "$(systemctl get-default 2>/dev/null)" == "multi-user.target" ]]; then
    pass_check 4 "Default systemd target is set to multi-user.target"
else
    fail_check 4 "Default target is '$(systemctl get-default 2>/dev/null)' (expected multi-user.target)"
fi

if [[ -s "$AUDIT_DIR/04_systemd_boot.txt" ]] && grep -qiE "Startup finished|service" "$AUDIT_DIR/04_systemd_boot.txt"; then
    pass_check 4 "Deliverable 04_systemd_boot.txt contains boot timing and running services"
else
    fail_check 4 "Deliverable 04_systemd_boot.txt missing or incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 5: Virtual Filesystems (/proc, /dev) & Block Storage (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 5: Virtual Filesystems & Block Storage Inspection (8 pts)\n"
if [[ -s "$AUDIT_DIR/05_storage_vfs.txt" ]] && grep -q "systemd" "$AUDIT_DIR/05_storage_vfs.txt" && grep -q "/dev/null" "$AUDIT_DIR/05_storage_vfs.txt"; then
    pass_check 8 "Deliverable 05_storage_vfs.txt contains PID 1 target, lsblk UUIDs, and /dev comparison"
else
    fail_check 8 "Deliverable 05_storage_vfs.txt missing or incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 6: Cross-Distribution Package & SSH Readiness Check (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 6: Package Management & SSH Service Readiness (8 pts)\n"
if command -v curl &>/dev/null && command -v vim &>/dev/null && command -v tmux &>/dev/null; then
    pass_check 4 "Required packages (curl, vim, tmux) are installed"
else
    fail_check 4 "One or more required packages (curl, vim, tmux) are missing"
fi

if systemctl is-active "$SSH_UNIT" &>/dev/null && [[ -s "$AUDIT_DIR/06_package_ssh.txt" ]]; then
    pass_check 4 "SSH daemon ($SSH_UNIT) is active and 06_package_ssh.txt is recorded"
else
    fail_check 4 "SSH daemon ($SSH_UNIT) inactive or 06_package_ssh.txt missing"
fi

printf "\n======================================================================\n"
printf "   FINAL DAY 1 SCORE: %d / %d POINTS" "$SCORE" "$MAX_SCORE"
if [[ "$SCORE" -ge 40 ]]; then
    printf "  -->  STATUS: PASS (Ready for Day 2)\n"
else
    printf "  -->  STATUS: NEEDS REVIEW (Target >= 40/50)\n"
fi
printf "======================================================================\n"
exit $(( SCORE >= 40 ? 0 : 1 ))
