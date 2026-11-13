#!/usr/bin/env bash
# ==============================================================================
# USS LINUX — DAY 5 AUTOMATED EVALUATION & GRADING SCRIPT (50 POINTS)
# Supports: AlmaLinux 10 (RHEL 10 / el10 family) & Ubuntu 22.04 / 24.04 LTS
# Target Workspace: /var/tmp/day5_audit/
# ==============================================================================
set -uo pipefail

AUDIT_DIR="/var/tmp/day5_audit"
SCORE=0
MAX_SCORE=50

printf "======================================================================\n"
printf "   USS LINUX DAY 5 EVALUATION REPORT — 50 POINTS\n"
printf "   Target Workspace: %s\n" "$AUDIT_DIR"
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
# TASK 1: Internal Subsystem Telemetry Using the USE Method (8 Points)
# ------------------------------------------------------------------------------
printf ">>> Task 1: Internal Subsystem USE Method Telemetry (8 pts)\n"
if [[ -s "$AUDIT_DIR/01_internal_use_metrics.txt" ]] && grep -q "MemAvailable" "$AUDIT_DIR/01_internal_use_metrics.txt" && grep -qiE "vmstat|procs" "$AUDIT_DIR/01_internal_use_metrics.txt"; then
    pass_check 8 "CPU, memory (available vs buffers), storage, and kernel error logs verified"
else
    fail_check 8 "01_internal_use_metrics.txt missing or incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 2: Network Stack Inspection & Persistent Sysctl Tuning (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 2: Network Stack & Persistent sysctl Tuning (8 pts)\n"
if [[ "$(sysctl -n vm.swappiness 2>/dev/null)" == "10" ]] && [[ -f /etc/sysctl.d/99-day5-tuning.conf ]] && [[ -s "$AUDIT_DIR/02_network_and_sysctl.txt" ]] && grep -q "vm.swappiness = 10" "$AUDIT_DIR/02_network_and_sysctl.txt"; then
    pass_check 8 "Network routes/sockets and persistent sysctl tuning (vm.swappiness=10) verified"
else
    fail_check 8 "sysctl tuning or 02_network_and_sysctl.txt missing/incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 3: Host Firewall Lockdown (firewalld on AlmaLinux 10 vs. UFW on Ubuntu) (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 3: Host Firewall Lockdown (firewalld / ufw) (8 pts)\n"
if [[ -s "$AUDIT_DIR/03_firewall_rules.txt" ]] && grep -qiE "http|80/tcp" "$AUDIT_DIR/03_firewall_rules.txt" && grep -qiE "ssh|22/tcp" "$AUDIT_DIR/03_firewall_rules.txt"; then
    pass_check 8 "Host firewall rules permitting SSH and HTTP verified in 03_firewall_rules.txt"
else
    fail_check 8 "03_firewall_rules.txt missing or HTTP/SSH rules not permitted"
fi


# ------------------------------------------------------------------------------
# TASK 4: OpenSSH Daemon Hardening & Syntax Validation (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 4: OpenSSH Daemon Hardening & Syntax Check (8 pts)\n"

SSH_CONFIG="/etc/ssh/sshd_config.d/99-day5-hardening.conf"
SSH_REPORT="$AUDIT_DIR/04_ssh_hardening.txt"

# Check 1: Configuration file exists
if ! sudo test -f "$SSH_CONFIG"; then
    fail_check 8 "SSH hardening configuration file missing"
else

    # Check 2: SSH configuration syntax
    if ! sudo sshd -t 2>/dev/null; then
        fail_check 8 "SSH daemon configuration syntax invalid"
    else

        # Check 3: Verify effective SSH settings
        SSH_EFFECTIVE=$(sudo sshd -T 2>/dev/null)

        ROOT_LOGIN=$(echo "$SSH_EFFECTIVE" | awk '$1=="permitrootlogin" {print $2}')
        MAX_AUTH=$(echo "$SSH_EFFECTIVE" | awk '$1=="maxauthtries" {print $2}')
        LOGIN_GRACE=$(echo "$SSH_EFFECTIVE" | awk '$1=="logingracetime" {print $2}')

        if [[ "$ROOT_LOGIN" != "no" ]] ||
           [[ "$MAX_AUTH" != "3" ]] ||
           [[ "$LOGIN_GRACE" != "30" ]]; then

            fail_check 8 "Effective SSH hardening settings are incorrect"

        # Check 4: Audit report exists and contains required directives
        elif [[ ! -s "$SSH_REPORT" ]] ||
             ! grep -qiE 'permitrootlogin[[:space:]]+no' "$SSH_REPORT" ||
             ! grep -qiE 'maxauthtries[[:space:]]+3' "$SSH_REPORT" ||
             ! grep -qiE 'logingracetime[[:space:]]+30' "$SSH_REPORT"; then

            fail_check 8 "SSH audit report missing or incomplete"

        else
            pass_check 8 "SSH hardening, effective settings, audit report and syntax verified"
        fi
    fi
fi


# ------------------------------------------------------------------------------
# TASK 5: Mandatory Access Control (SELinux Contexts vs. AppArmor Profiles) (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 5: Mandatory Access Control (SELinux / AppArmor) (8 pts)\n"
if [[ -s "$AUDIT_DIR/05_mac_security_audit.txt" ]] && grep -q "200 OK" "$AUDIT_DIR/05_mac_security_audit.txt"; then
    pass_check 8 "Mandatory Access Control audit and HTTP 200 response verified"
else
    fail_check 8 "05_mac_security_audit.txt missing or HTTP check failed"
fi

# ------------------------------------------------------------------------------
# TASK 6: 7-Step Production Fault Recovery & Backup Drill (10 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 6: 7-Step Fault Diagnosis, Recovery & /var/backups (10 pts)\n"
if systemctl is-active nginx &>/dev/null && [[ -f /var/backups/day5_etc_nginx.tar.gz ]] && [[ -f /var/backups/day5_etc_nginx.tar.gz.sha256 ]] && (cd /var/backups && sha256sum -c day5_etc_nginx.tar.gz.sha256 &>/dev/null) && [[ -s "$AUDIT_DIR/06_fault_recovery_report.txt" ]] && grep -q "unknown_broken_directive" "$AUDIT_DIR/06_fault_recovery_report.txt"; then
    pass_check 10 "7-Step fault diagnosis, recovery, and /var/backups archive verified"
else
    fail_check 10 "Fault recovery report or /var/backups/day5_etc_nginx.tar.gz verification failed"
fi

printf "\n======================================================================\n"
printf "   FINAL DAY 5 SCORE: %d / %d POINTS" "$SCORE" "$MAX_SCORE"
if [[ "$SCORE" -ge 40 ]]; then
    printf "  -->  STATUS: PASS (Course Complete — Capstone Ready!)\n"
else
    printf "  -->  STATUS: NEEDS REVIEW (Target >= 40/50)\n"
fi
printf "======================================================================\n"
exit $(( SCORE >= 40 ? 0 : 1 ))
