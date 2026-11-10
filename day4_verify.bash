#!/usr/bin/env bash
# ==============================================================================
# USS LINUX — DAY 4 AUTOMATED EVALUATION & GRADING SCRIPT (50 POINTS)
# Supports: AlmaLinux 10 (RHEL 10 / el10 family) & Ubuntu 22.04 / 24.04 LTS
# Target Workspace: /var/tmp/day4_audit/
# ==============================================================================
set -uo pipefail

AUDIT_DIR="/var/tmp/day4_audit"
SCORE=0
MAX_SCORE=50

printf "======================================================================\n"
printf "   USS LINUX DAY 4 EVALUATION REPORT — 50 POINTS\n"
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
# TASK 1: Process Hierarchy & Nice/Renice CPU Priority (8 Points)
# ------------------------------------------------------------------------------
printf ">>> Task 1: Process Inspection & nice/renice Priority Tuning (8 pts)\n"
if [[ -s "$AUDIT_DIR/01_process_priority.txt" ]] && grep -q "new priority 15" "$AUDIT_DIR/01_process_priority.txt"; then
    pass_check 8 "Dynamic priority adjustment to nice +15 recorded in 01_process_priority.txt"
else
    fail_check 8 "01_process_priority.txt missing or renice adjustment not recorded"
fi

# ------------------------------------------------------------------------------
# TASK 2: Graceful Signal Handling (SIGHUP & SIGTERM) (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 2: SIGHUP Daemon Reload & SIGTERM Graceful Stop (8 pts)\n"
if [[ -s "$AUDIT_DIR/02_signal_handling.txt" ]] && grep -q "Unchanged!" "$AUDIT_DIR/02_signal_handling.txt" && grep -q "SIGTERM" "$AUDIT_DIR/02_signal_handling.txt"; then
    pass_check 8 "SIGHUP master PID preservation and SIGTERM graceful exit verified"
else
    fail_check 8 "02_signal_handling.txt missing or signal proofs incomplete"
fi

# ------------------------------------------------------------------------------
# TASK 3: Health-Monitor Script with Signal Trap & Cron Schedule (10 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 3: Health Monitor Script with Signal trap & Cron (10 pts)\n"
if [[ -x /usr/local/bin/day4_health_check.sh ]] && [[ -f /etc/cron.d/day4_health ]] && [[ -s "$AUDIT_DIR/03_health_script_cron.txt" ]] && grep -q "Remaining /tmp/day4_health_.*lock files: 0" "$AUDIT_DIR/03_health_script_cron.txt"; then
    pass_check 10 "/usr/local/bin/day4_health_check.sh, trap lock cleanup, and /etc/cron.d/day4_health verified"
else
    fail_check 10 "Health monitor script, trap cleanup, or /etc/cron.d/day4_health missing"
fi

# ------------------------------------------------------------------------------
# TASK 4: Repository Inspection & Isolated Microservice in /opt (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 4: Repositories & Isolated Service User in /opt (8 pts)\n"
if id metricsvc &>/dev/null && getent passwd metricsvc | grep -q "nologin" && [[ -f /opt/metrics-api/status.json ]] && [[ -s "$AUDIT_DIR/04_repo_and_app_deploy.txt" ]]; then
    pass_check 8 "Locked metricsvc account and /opt/metrics-api payload verified"
else
    fail_check 8 "metricsvc user, nologin shell, or /opt/metrics-api missing"
fi

# ------------------------------------------------------------------------------
# TASK 5: Custom Systemd Unit (metrics-api.service) on Port 8090 (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 5: Custom metrics-api.service Systemd Unit (8 pts)\n"
if systemctl is-active metrics-api.service &>/dev/null && curl -s http://127.0.0.1:8090/status.json | grep -q "uss-day4-metrics-api" && [[ -s "$AUDIT_DIR/05_systemd_custom_unit.txt" ]]; then
    pass_check 8 "metrics-api.service active and responding with status: ok on port 8090"
else
    fail_check 8 "metrics-api.service inactive, unreachable on port 8090, or deliverable missing"
fi

# ------------------------------------------------------------------------------
# TASK 6: Controlled Configuration Change, Validation & Rollback (8 Points)
# ------------------------------------------------------------------------------
printf "\n>>> Task 6: Controlled Config Change (8091) & Rollback (8090) (8 pts)\n"
if [[ -s "$AUDIT_DIR/06_config_rollback_proof.txt" ]] && grep -q ":8091" "$AUDIT_DIR/06_config_rollback_proof.txt" && grep -q ":8090" "$AUDIT_DIR/06_config_rollback_proof.txt" && grep -qi "test is successful" "$AUDIT_DIR/06_config_rollback_proof.txt"; then
    pass_check 8 "Forward change to 8091, rollback to 8090, and nginx -t syntax verified"
else
    fail_check 8 "06_config_rollback_proof.txt missing or change/rollback proof incomplete"
fi

printf "\n======================================================================\n"
printf "   FINAL DAY 4 SCORE: %d / %d POINTS" "$SCORE" "$MAX_SCORE"
if [[ "$SCORE" -ge 40 ]]; then
    printf "  -->  STATUS: PASS (Ready for Day 5)\n"
else
    printf "  -->  STATUS: NEEDS REVIEW (Target >= 40/50)\n"
fi
printf "======================================================================\n"
exit $(( SCORE >= 40 ? 0 : 1 ))