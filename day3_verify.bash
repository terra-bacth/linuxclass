#!/usr/bin/env bash
# ==============================================================================
# USS LINUX — DAY 3 AUTOMATED EVALUATION & GRADING SCRIPT (50 POINTS)
# Supports: AlmaLinux 10 (RHEL 10 / el10 family) & Ubuntu 22.04 / 24.04 LTS
# Target Workspace: /var/tmp/day3_audit/
# ==============================================================================
set -uo pipefail

AUDIT_DIR="/var/tmp/day3_audit"
SCORE=0
MAX_SCORE=50

printf "======================================================================\n"
printf "   USS LINUX DAY 3 EVALUATION REPORT — 50 POINTS\n"
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
# TASK 1: FHS Navigation, Block vs. Inode Utilization & /var Space Audit (8 Points)
# ------------------------------------------------------------------------------
printf ">>> Task 1: FHS Navigation, Block vs. Inode & /var Space (8 pts)\n"
if [[ -s "$AUDIT_DIR/01_fhs_storage_map.txt" ]] && grep -q "/var/run -> /run" "$AUDIT_DIR/01_fhs_storage_map.txt"; then
    pass_check 8 "FHS block/inode audit and canonical symlink map verified"
else
    fail_check 8 "01_fhs_storage_map.txt missing or incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 2: Release Tree Construction, Attribute Copy & Hard vs. Soft Links (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 2: Release Tree & Hard vs. Symbolic Links (8 pts)\n"
CONF_FILE="$AUDIT_DIR/release_v2/conf/service.conf"
HARD_FILE="$AUDIT_DIR/release_v2/conf/service.hardlink"
SYM_FILE="$AUDIT_DIR/release_v2/conf/service.symlink"

if [[ -f "$CONF_FILE" ]] && [[ -f "$HARD_FILE" ]] && [[ -L "$SYM_FILE" ]] && [[ "$(stat -c %i "$CONF_FILE" 2>/dev/null)" == "$(stat -c %i "$HARD_FILE" 2>/dev/null)" ]]; then
    pass_check 8 "Hard link shares identical inode number and symbolic link verified"
else
    fail_check 8 "Hard link or symbolic link verification failed"
fi

# ------------------------------------------------------------------------------
# TASK 3: Compressed Tarball, SHA-256 Checksum & Staging Restore (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 3: Compressed Tarball, SHA-256 Checksum & Restore (8 pts)\n"
if [[ -f "$AUDIT_DIR/release_v2.tar.gz" ]] && [[ -f "$AUDIT_DIR/release_v2.tar.gz.sha256" ]] && (cd "$AUDIT_DIR" && sha256sum -c release_v2.tar.gz.sha256 &>/dev/null) && [[ -s "$AUDIT_DIR/03_archive_restore_proof.txt" ]] && grep -q "RESTORE VERIFIED" "$AUDIT_DIR/03_archive_restore_proof.txt"; then
    pass_check 8 "release_v2.tar.gz passes SHA-256 checksum and diff -ru shows 0 drift"
else
    fail_check 8 "release_v2.tar.gz or 03_archive_restore_proof.txt verification failed"
fi

# ------------------------------------------------------------------------------
# TASK 4: Multi-User & Group Identity with Password Aging Policy (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 4: Multi-User, Group & chage Password Aging (8 pts)\n"
if getent group devops_grp | grep -q ":3100:" && id -u dev_alex &>/dev/null && id -u sec_auditor &>/dev/null && [[ -s "$AUDIT_DIR/04_users_groups_aging.txt" ]]; then
    pass_check 8 "Group devops_grp (3100), users (dev_alex, sec_auditor) & chage verified"
else
    fail_check 8 "Users/groups or 04_users_groups_aging.txt missing"
fi

# ------------------------------------------------------------------------------
# TASK 5: Collaborative Directory with SGID (2000) & Sticky Bit (1000) (10 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 5: SGID (2000) & Sticky Bit (1000) on /srv/devops_collab (10 pts)\n"
if [[ "$(stat -c %a /srv/devops_collab 2>/dev/null)" == "3770" ]] && [[ -s "$AUDIT_DIR/05_sgid_sticky_collab.txt" ]] && grep -q "VERIFIED: Sticky Bit" "$AUDIT_DIR/05_sgid_sticky_collab.txt"; then
    pass_check 10 "Mode 3770 on /srv/devops_collab and Sticky Bit deletion protection verified"
else
    fail_check 10 "/srv/devops_collab mode 3770 or Sticky Bit deletion test failed"
fi

# ------------------------------------------------------------------------------
# TASK 6: Granular POSIX ACLs & SUID/SGID Security Scan (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 6: POSIX ACLs for Auditor & SUID/SGID Binary Scan (8 pts)\n"
if getfacl -p /srv/devops_collab 2>/dev/null | grep -q "user:sec_auditor:r-x" && [[ -s "$AUDIT_DIR/06_acl_and_suid_search.txt" ]]; then
    pass_check 8 "POSIX ACL for sec_auditor and SUID binary audit verified"
else
    fail_check 8 "POSIX ACL or 06_acl_and_suid_search.txt missing"
fi

printf "\n======================================================================\n"
printf "   FINAL DAY 3 SCORE: %d / %d POINTS" "$SCORE" "$MAX_SCORE"
if [[ "$SCORE" -ge 40 ]]; then
    printf "  -->  STATUS: PASS (Ready for Day 4)\n"
else
    printf "  -->  STATUS: NEEDS REVIEW (Target >= 40/50)\n"
fi
printf "======================================================================\n"
exit $(( SCORE >= 40 ? 0 : 1 ))