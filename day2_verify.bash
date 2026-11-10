#!/usr/bin/env bash
# ==============================================================================
# USS LINUX — DAY 2 AUTOMATED EVALUATION & GRADING SCRIPT (50 POINTS)
# Supports: AlmaLinux 10 (RHEL 10 / el10 family) & Ubuntu 22.04 / 24.04 LTS
# Target Workspace: /var/tmp/day2_audit/
# ==============================================================================
set -uo pipefail

AUDIT_DIR="/var/tmp/day2_audit"
SCORE=0
MAX_SCORE=50

printf "======================================================================\n"
printf "   USS LINUX DAY 2 EVALUATION REPORT — 50 POINTS\n"
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
# TASK 1: Web Server Package Lifecycle, File Ownership & HTTP Verification (8 Points)
# ------------------------------------------------------------------------------
printf ">>> Task 1: Nginx Package Lifecycle, File Ownership & HTTP (8 pts)\n"
if systemctl is-active nginx &>/dev/null && [[ -s "$AUDIT_DIR/01_nginx_package_audit.txt" ]] && grep -q "200 OK" "$AUDIT_DIR/01_nginx_package_audit.txt"; then
    pass_check 8 "Nginx is active, responds with HTTP 200, and 01_nginx_package_audit.txt is verified"
else
    fail_check 8 "Nginx inactive or 01_nginx_package_audit.txt missing/incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 2: Shell Quoting, Variable Expansion & Space-Safe File Manipulation (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 2: Quoting, Variable Expansion & Space-Safe Files (8 pts)\n"
if [[ -s "$AUDIT_DIR/Space Test Directory/Q4 Financial Summary 2026.txt" ]] && [[ -s "$AUDIT_DIR/02_quoting_variables.txt" ]] && grep -qi "Double-Quoted Expansion" "$AUDIT_DIR/02_quoting_variables.txt"; then
    pass_check 8 "Space-safe file and quoting expansion in 02_quoting_variables.txt verified"
else
    fail_check 8 "Space-safe file or 02_quoting_variables.txt missing/incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 3: Persistent Environment Variables & Shell Startup Profiles (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 3: Persistent Environment Profile in /etc/profile.d/ (8 pts)\n"
if [[ -f /etc/profile.d/uss_day2.sh ]] && grep -q "USS_CLUSTER_ENV" /etc/profile.d/uss_day2.sh && [[ -s "$AUDIT_DIR/03_environment_profile.txt" ]] && grep -q "USS_CLUSTER_ENV=staging" "$AUDIT_DIR/03_environment_profile.txt"; then
    pass_check 8 "/etc/profile.d/uss_day2.sh and child subshell inheritance in 03_environment_profile.txt verified"
else
    fail_check 8 "/etc/profile.d/uss_day2.sh missing or 03_environment_profile.txt incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 4: Defensive Host Inventory Script with Exit Status Validation (10 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 4: Defensive Host Inventory Script & Exit Code Validation (10 pts)\n"
if [[ -x /usr/local/bin/day2_inventory.sh ]] && [[ -s "$AUDIT_DIR/04_inventory_script_output.txt" ]] && grep -q "exit code: 2" "$AUDIT_DIR/04_inventory_script_output.txt"; then
    pass_check 10 "/usr/local/bin/day2_inventory.sh exists and missing-file exit status 2 verified"
else
    fail_check 10 "/usr/local/bin/day2_inventory.sh missing or exit code 2 not recorded"
fi

# ------------------------------------------------------------------------------
# TASK 5: Standard I/O Redirection & Multi-Stage Log Analysis Pipelines (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 5: Standard I/O Redirection & Multi-Stage Log Pipelines (8 pts)\n"
if [[ -s "$AUDIT_DIR/web_access.log" ]] && [[ -s "$AUDIT_DIR/05_log_pipeline_metrics.txt" ]] && grep -q "Total Log Lines: 12" "$AUDIT_DIR/05_log_pipeline_metrics.txt" && grep -q "404" "$AUDIT_DIR/05_log_pipeline_metrics.txt"; then
    pass_check 8 "web_access.log (12 lines) and multi-stage pipeline metrics in 05_log_pipeline_metrics.txt verified"
else
    fail_check 8 "web_access.log or 05_log_pipeline_metrics.txt missing/incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 6: Conditional Expressions & Security Threshold Alerting (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 6: Conditional Expressions & Threshold Alerting (8 pts)\n"
if [[ -s "$AUDIT_DIR/06_expression_alerts.txt" ]] && grep -q "\[ALERT-4XX\]" "$AUDIT_DIR/06_expression_alerts.txt" && grep -q "\[SEC-BLOCK\]" "$AUDIT_DIR/06_expression_alerts.txt"; then
    pass_check 8 "Conditional threshold alerts in 06_expression_alerts.txt verified"
else
    fail_check 8 "06_expression_alerts.txt missing or threshold alerts not triggered"
fi

printf "\n======================================================================\n"
printf "   FINAL DAY 2 SCORE: %d / %d POINTS" "$SCORE" "$MAX_SCORE"
if [[ "$SCORE" -ge 40 ]]; then
    printf "  -->  STATUS: PASS (Ready for Day 3)\n"
else
    printf "  -->  STATUS: NEEDS REVIEW (Target >= 40/50)\n"
fi
printf "======================================================================\n"
exit $(( SCORE >= 40 ? 0 : 1 ))