#!/bin/bash
# ============================================================
#
#   ███╗   ███╗██╗ █████╗ ██████╗      ██████╗  █████╗ ██████╗  █████╗ ██████╗
#   ████╗ ████║██║██╔══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
#   ██╔████╔██║██║███████║██████╔╝     ██████╔╝███████║██║  ██║███████║██████╔╝
#   ██║╚██╔╝██║██║██╔══██║██╔══██╗     ██╔══██╗██╔══██║██║  ██║██╔══██║██╔══██╗
#   ██║ ╚═╝ ██║██║██║  ██║██████╔╝     ██║  ██║██║  ██║██████╔╝██║  ██║██║  ██║
#   ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═════╝      ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
#
#   Mail-in-a-Box Security & Health Audit Tool
#   by Anton Babaskin — github.com/Anton-Babaskin/miab-radar
#   Version: 3.0
#
# ============================================================

# Fail on unset vars and bad pipes, but NOT on non-zero exit (grep -c returns 1 on 0 matches)
set -uo pipefail

# --- Colors ---
RED='\033[0;31m'
YEL='\033[0;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLU='\033[0;34m'
MAG='\033[0;35m'
WHT='\033[1;37m'
BLD='\033[1m'
DIM='\033[2m'
RST='\033[0m'
G1='\033[38;5;220m'
G2='\033[38;5;214m'
G3='\033[38;5;208m'
G4='\033[38;5;202m'
G5='\033[38;5;196m'
G6='\033[38;5;166m'

# --- Counters ---
COUNT_OK=0
COUNT_WARN=0
COUNT_FAIL=0

# --- Recommendations collector ---
declare -a RECOMMENDATIONS=()
rec() { RECOMMENDATIONS+=("$1"); }

# --- Config ---
MAIL_LOG="/var/log/mail.log"
MAIL_LOGS_ALL=(/var/log/mail.log /var/log/mail.log.1 /var/log/mail.log.{2..4}.gz)
MAILBOX_DIR="/home/user-data/mail/mailboxes"
HOURS=${1:-24}

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✘${RST}  This script must be run as root."
    exit 1
fi

# --- Safe grep -c (returns 0 on no match instead of failing) ---
gcount() { grep -c "$@" || true; }

# --- Output helpers ---
ok()   { ((COUNT_OK++))   || true; echo -e " ${GRN}✔${RST}  $1"; }
warn() { ((COUNT_WARN++)) || true; echo -e " ${YEL}⚠${RST}  $1"; }
fail() { ((COUNT_FAIL++)) || true; echo -e " ${RED}✘${RST}  $1"; }
info() { echo -e " ${CYN}→${RST}  $1"; }
hdr()  { echo -e "\n${BLD}${CYN}══ $1 ══${RST}"; }

# --- Time-filtered log ---
filter_log_by_hours() {
    local FILE="$1" H="$2" CUTOFF YEAR
    CUTOFF=$(date -d "${H} hours ago" '+%s' 2>/dev/null) || CUTOFF=0
    if [[ "$CUTOFF" -eq 0 ]]; then
        cat "$FILE" 2>/dev/null; return
    fi
    YEAR=$(date '+%Y')
    awk -v cutoff="$CUTOFF" -v year="$YEAR" '
    BEGIN {
        split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", m)
        for (i in m) mon[m[i]] = i
    }
    {
        ts = mktime(year " " mon[$1] " " $2 " " gensub(/:/, " ", "g", $3))
        if (ts >= cutoff) print
    }' "$FILE" 2>/dev/null
}

# ============================================================
# HEADER
# ============================================================
clear
echo ""
echo -e "${G1}${BLD}  ███╗   ███╗██╗ █████╗ ██████╗ ${RST}     ${G3}${BLD} ██████╗  █████╗ ██████╗  █████╗ ██████╗ ${RST}"
echo -e "${G1}${BLD}  ████╗ ████║██║██╔══██╗██╔══██╗${RST}     ${G3}${BLD} ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗${RST}"
echo -e "${G2}${BLD}  ██╔████╔██║██║███████║██████╔╝${RST}     ${G4}${BLD} ██████╔╝███████║██║  ██║███████║██████╔╝${RST}"
echo -e "${G2}${BLD}  ██║╚██╔╝██║██║██╔══██║██╔══██╗${RST}     ${G4}${BLD} ██╔══██╗██╔══██║██║  ██║██╔══██║██╔══██╗${RST}"
echo -e "${G3}${BLD}  ██║ ╚═╝ ██║██║██║  ██║██████╔╝${RST}     ${G5}${BLD} ██║  ██║██║  ██║██████╔╝██║  ██║██║  ██║${RST}"
echo -e "${G3}${BLD}  ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ${RST}     ${G5}${BLD} ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝${RST}"
echo -e "                                                                    ${DIM}by ${G1}Anton Babaskin${RST}"
echo ""

HOSTNAME=$(hostname)
IPV4=$(curl -s -4 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
IPV6=$(curl -s -6 --connect-timeout 5 --max-time 10 ifconfig.me 2>/dev/null || echo "")
MIAB_VER=$(cd /root/mailinabox 2>/dev/null && git describe --tags 2>/dev/null || echo "unknown")
UPTIME_STR=$(uptime -p 2>/dev/null || uptime | sed 's/.*up /up /' | sed 's/,.*load.*//')
LOAD=$(cat /proc/loadavg 2>/dev/null | awk '{print $1" "$2" "$3}')

echo -e "  ${DIM}Host: ${BLD}${HOSTNAME}${RST}  ${DIM}IPv4: ${BLD}${IPV4}${RST}  ${DIM}IPv6: ${BLD}${IPV6:-none}${RST}"
echo -e "  ${DIM}MIAB: ${BLD}${MIAB_VER}${RST}  ${DIM}Period: last ${BLD}${HOURS}h${RST}  ${DIM}Up: ${BLD}${UPTIME_STR}${RST}"
echo -e "  ${DIM}Load: ${BLD}${LOAD}${RST}  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${RST}"
echo ""

# Prepare time-filtered log
FILTERED_LOG=$(mktemp)
_TLS_TMP=$(mktemp)
trap "rm -f '$FILTERED_LOG' '$_TLS_TMP'" EXIT
filter_log_by_hours "$MAIL_LOG" "$HOURS" > "$FILTERED_LOG"

# ============================================================
# 1. SERVICES
# ============================================================
hdr "SERVICES"

check_svc() {
    local SVC="$1" LABEL="$2"
    if systemctl is-active "$SVC" &>/dev/null; then
        ok "${LABEL}: running"
    elif systemctl list-unit-files 2>/dev/null | grep -q "^${SVC}"; then
        fail "${LABEL}: ${RED}not running${RST}"
        rec "Start ${LABEL}: systemctl start ${SVC}"
    else
        echo -e " ${DIM}–${RST}  ${DIM}${LABEL}: not installed${RST}"
    fi
}

check_svc postfix       "Postfix (SMTP)"
check_svc dovecot       "Dovecot (IMAP)"
check_svc nginx         "Nginx (Web)"
check_svc fail2ban      "Fail2ban"
check_svc nsd           "NSD (DNS)"
check_svc opendkim      "OpenDKIM"
check_svc postgrey      "Postgrey"
check_svc spampd        "SpamPD"

# PHP-FPM (dynamic name)
PHP_FPM=$(systemctl list-units --type=service --state=running 2>/dev/null | grep -oP 'php[0-9.]+-fpm\.service' | head -1)
if [[ -n "$PHP_FPM" ]]; then
    ok "PHP-FPM: running (${PHP_FPM%.service})"
else
    PHP_FPM_AVAIL=$(systemctl list-unit-files 2>/dev/null | grep -oP 'php[0-9.]+-fpm\.service' | head -1)
    if [[ -n "$PHP_FPM_AVAIL" ]]; then
        fail "PHP-FPM: ${RED}not running${RST}"
        rec "Start PHP-FPM: systemctl start ${PHP_FPM_AVAIL}"
    fi
fi

# ============================================================
# 2. BLACKLIST STATUS
# ============================================================
hdr "BLACKLIST STATUS"

check_bl() {
    local NAME=$1 HOST=$2 REV_IP=$3
    local QUERY
    QUERY=$(dig +short +time=3 +tries=1 -t a "${REV_IP}.${HOST}" 2>/dev/null)
    if [[ -z "$QUERY" ]]; then
        ok "${NAME}"
    else
        fail "${NAME} — ${RED}LISTED${RST} ($QUERY)"
        rec "Delist from ${NAME}: check ${HOST} removal process"
    fi
}

check_bl_v6() {
    local NAME=$1 HOST=$2 IP=$3
    local EXPANDED
    EXPANDED=$(python3 -c "
import ipaddress,sys
try:
    a=ipaddress.ip_address('${IP}')
    print('.'.join(reversed(a.exploded.replace(':',''))))
except: sys.exit(1)
" 2>/dev/null) || return
    local QUERY
    QUERY=$(dig +short +time=3 +tries=1 -t a "${EXPANDED}.${HOST}" 2>/dev/null)
    if [[ -z "$QUERY" ]]; then ok "${NAME}"; else
        fail "${NAME} — ${RED}LISTED${RST} ($QUERY)"
        rec "Delist IPv6 from ${NAME}"
    fi
}

check_dbl() {
    local NAME=$1 HOST=$2 DOMAIN=$3
    local QUERY
    QUERY=$(dig +short +time=3 +tries=1 -t a "${DOMAIN}.${HOST}" 2>/dev/null)
    if [[ -z "$QUERY" ]]; then ok "${NAME} (${DOMAIN})"; else
        fail "${NAME} (${DOMAIN}) — ${RED}LISTED${RST} ($QUERY)"
        rec "Delist ${DOMAIN} from ${NAME}: https://www.spamhaus.org/lookup/"
    fi
}

IPV4_REV=$(echo "$IPV4" | awk -F. '{print $4"."$3"."$2"."$1}')
DOMAIN=$(postconf -h mydomain 2>/dev/null | head -1)

check_bl  "Spamhaus ZEN (IPv4)" "zen.spamhaus.org" "$IPV4_REV"
check_bl  "SpamCop     (IPv4)" "bl.spamcop.net" "$IPV4_REV"
check_bl  "Barracuda   (IPv4)" "b.barracudacentral.org" "$IPV4_REV"
check_bl  "SORBS       (IPv4)" "dnsbl.sorbs.net" "$IPV4_REV"

if [[ -n "$IPV6" ]]; then
    check_bl_v6 "Spamhaus ZEN (IPv6)" "zen.spamhaus.org" "$IPV6"
    check_bl_v6 "SORBS       (IPv6)" "dnsbl.sorbs.net" "$IPV6"
fi

check_dbl "Spamhaus DBL" "dbl.spamhaus.org" "$DOMAIN"
check_dbl "Spamhaus DBL" "dbl.spamhaus.org" "box.${DOMAIN}"

# ============================================================
# 3. DNS RECORDS
# ============================================================
hdr "DNS RECORDS"

PTR=$(dig +short -x "$IPV4" 2>/dev/null | sed 's/\.$//')
if [[ "$PTR" == "$HOSTNAME" ]]; then
    ok "PTR (rDNS): ${PTR}"
elif [[ -n "$PTR" ]]; then
    warn "PTR mismatch: PTR=${YEL}${PTR}${RST} vs hostname=${YEL}${HOSTNAME}${RST}"
    rec "Fix PTR record at hosting provider → should be ${HOSTNAME}"
else
    fail "PTR (rDNS): ${RED}not set${RST}"
    rec "Set PTR (rDNS) to ${HOSTNAME} at your VPS provider"
fi

SPF=$(dig +short TXT "$DOMAIN" 2>/dev/null | grep -i "v=spf1" | head -1)
if [[ -n "$SPF" ]]; then
    ok "SPF: ${DIM}${SPF}${RST}"
    if echo "$SPF" | grep -q "+all"; then
        warn "SPF uses ${YEL}+all${RST} — anyone can send as your domain!"
        rec "Fix SPF: replace +all with ~all or -all"
    fi
else
    fail "SPF: ${RED}not found for ${DOMAIN}${RST}"
    rec "Add SPF TXT record for ${DOMAIN}"
fi

DKIM_FOUND=""
for SEL in mail default dkim google; do
    DKIM=$(dig +short TXT "${SEL}._domainkey.${DOMAIN}" 2>/dev/null | head -1)
    if [[ -n "$DKIM" ]]; then
        ok "DKIM: ${DIM}${SEL}._domainkey.${DOMAIN}${RST}"
        DKIM_FOUND=1; break
    fi
done
[[ -z "$DKIM_FOUND" ]] && { fail "DKIM: ${RED}no record for ${DOMAIN}${RST}"; rec "Configure DKIM and publish DNS record"; }

DMARC=$(dig +short TXT "_dmarc.${DOMAIN}" 2>/dev/null | head -1)
if [[ -n "$DMARC" ]]; then
    ok "DMARC: ${DIM}${DMARC}${RST}"
    echo "$DMARC" | grep -qi "p=none" && {
        warn "DMARC policy is ${YEL}p=none${RST} — no enforcement"
        rec "Tighten DMARC: p=quarantine or p=reject"
    }
else
    fail "DMARC: ${RED}not found for ${DOMAIN}${RST}"
    rec "Add DMARC record: _dmarc.${DOMAIN}"
fi

MTASTS=$(dig +short TXT "_mta-sts.${DOMAIN}" 2>/dev/null | head -1)
[[ -n "$MTASTS" ]] && ok "MTA-STS: configured" || info "MTA-STS: not configured ${DIM}(optional)${RST}"

TLSA=$(dig +short TLSA "_25._tcp.${HOSTNAME}" 2>/dev/null | head -1)
[[ -n "$TLSA" ]] && ok "DANE/TLSA: configured" || info "DANE/TLSA: not configured ${DIM}(optional)${RST}"

MX=$(dig +short MX "$DOMAIN" 2>/dev/null | head -3)
if [[ -n "$MX" ]]; then
    ok "MX records:"
    echo "$MX" | while read -r LINE; do echo -e "     ${DIM}${LINE}${RST}"; done
else
    fail "MX: ${RED}no records for ${DOMAIN}${RST}"
    rec "Add MX record → ${HOSTNAME}"
fi

# ============================================================
# 4. TLS CERTIFICATE
# ============================================================
hdr "TLS CERTIFICATE"

SMTP_HOST=$(postconf -h myhostname 2>/dev/null || echo "$HOSTNAME")

get_cert_info() {
    local LABEL="$1"; shift
    timeout 5 openssl s_client "$@" -servername "$SMTP_HOST" </dev/null 2>/dev/null > "$_TLS_TMP"
    openssl x509 -noout -dates -subject < "$_TLS_TMP" 2>/dev/null
}

show_cert_status() {
    local CERT_INFO="$1" LABEL="$2"
    local CERT_SUBJ CERT_END CERT_END_EPOCH NOW_EPOCH DAYS_LEFT
    CERT_SUBJ=$(echo "$CERT_INFO" | grep "subject=" | sed 's/.*subject= *//' | xargs)
    CERT_END=$(echo "$CERT_INFO" | grep "notAfter=" | sed 's/notAfter=//')
    CERT_END_EPOCH=$(date -d "$CERT_END" '+%s' 2>/dev/null || echo 0)
    NOW_EPOCH=$(date '+%s')
    DAYS_LEFT=$(( (CERT_END_EPOCH - NOW_EPOCH) / 86400 ))

    if [[ "$DAYS_LEFT" -le 0 ]]; then
        fail "TLS EXPIRED (${LABEL}): ${RED}${CERT_END}${RST} — ${CERT_SUBJ}"
        rec "URGENT: Renew TLS cert! sudo mailinabox"
    elif [[ "$DAYS_LEFT" -le 7 ]]; then
        fail "TLS expires in ${RED}${DAYS_LEFT}d${RST} (${LABEL}) — ${CERT_SUBJ}"
        rec "TLS cert expiring soon — run: sudo mailinabox"
    elif [[ "$DAYS_LEFT" -le 30 ]]; then
        warn "TLS expires in ${YEL}${DAYS_LEFT}d${RST} (${LABEL}) — ${CERT_SUBJ}"
    else
        ok "TLS valid (${LABEL}): ${DAYS_LEFT}d left — ${CERT_SUBJ}"
    fi
}

TLS_FOUND=0
declare -A TLS_METHODS=(
    ["587/STARTTLS"]="-connect ${SMTP_HOST}:587 -starttls smtp"
    ["25/STARTTLS"]="-connect ${SMTP_HOST}:25 -starttls smtp"
    ["465/SMTPS"]="-connect ${SMTP_HOST}:465"
    ["993/IMAPS"]="-connect ${SMTP_HOST}:993"
    ["443/HTTPS"]="-connect ${SMTP_HOST}:443"
)
TLS_ORDER=("587/STARTTLS" "25/STARTTLS" "465/SMTPS" "993/IMAPS" "443/HTTPS")

for LABEL in "${TLS_ORDER[@]}"; do
    # shellcheck disable=SC2086
    CERT_INFO=$(get_cert_info "$LABEL" ${TLS_METHODS[$LABEL]})
    if [[ -n "$CERT_INFO" ]]; then
        show_cert_status "$CERT_INFO" "$LABEL"
        TLS_FOUND=1
        break
    fi
done

[[ "$TLS_FOUND" -eq 0 ]] && {
    warn "Could not retrieve TLS cert from any port"
    rec "Debug TLS: openssl s_client -connect ${SMTP_HOST}:587 -starttls smtp"
}

# ============================================================
# 5. DISK SPACE
# ============================================================
hdr "DISK SPACE"

while read -r USAGE MOUNT; do
    [[ -z "$USAGE" ]] && continue
    PCT=${USAGE%%%}
    if [[ "$PCT" -ge 95 ]]; then
        fail "${MOUNT}: ${RED}${USAGE}${RST}"
        rec "CRITICAL: ${MOUNT} at ${USAGE} — free space now"
    elif [[ "$PCT" -ge 80 ]]; then
        warn "${MOUNT}: ${YEL}${USAGE}${RST}"
        rec "Disk ${MOUNT} at ${USAGE} — cleanup needed"
    else
        ok "${MOUNT}: ${USAGE} used"
    fi
done < <(df -h --output=pcent,target / /home /home/user-data 2>/dev/null | tail -n +2 | sort -u)

while read -r USAGE MOUNT; do
    [[ -z "$USAGE" ]] && continue
    PCT=${USAGE%%%}; PCT=${PCT// /}
    [[ -z "$PCT" || "$PCT" == "-" ]] && continue
    if [[ "$PCT" -ge 90 ]]; then
        fail "Inodes ${MOUNT}: ${RED}${USAGE}${RST}"
        rec "Inode exhaustion on ${MOUNT}"
    elif [[ "$PCT" -ge 70 ]]; then
        warn "Inodes ${MOUNT}: ${YEL}${USAGE}${RST}"
    fi
done < <(df -i --output=ipcent,target / /home 2>/dev/null | tail -n +2 | sort -u)

[[ -d "/home/user-data" ]] && {
    UDATA_SIZE=$(du -sh /home/user-data 2>/dev/null | awk '{print $1}')
    info "Total /home/user-data: ${BLD}${UDATA_SIZE}${RST}"
}

# ============================================================
# 6. MAIL QUEUE
# ============================================================
hdr "MAIL QUEUE"

QUEUE_COUNT=$(postqueue -p 2>/dev/null | grep -c "^[A-F0-9]") || QUEUE_COUNT=0
QUEUE_COUNT=$((QUEUE_COUNT + 0))
if [[ "$QUEUE_COUNT" -eq 0 ]]; then
    ok "Queue is empty"
elif [[ "$QUEUE_COUNT" -lt 10 ]]; then
    warn "Queue: ${YEL}${QUEUE_COUNT} messages${RST}"
    postqueue -p 2>/dev/null | grep "^[A-F0-9]" | awk '{print "     "$0}'
else
    fail "Queue: ${RED}${QUEUE_COUNT} messages${RST}"
    postqueue -p 2>/dev/null | grep "^[A-F0-9]" | head -5 | awk '{print "     "$0}'
    echo -e "     ${DIM}... and $((QUEUE_COUNT-5)) more${RST}"
    rec "Queue has ${QUEUE_COUNT} msgs — investigate: postqueue -p | less"
fi

# Oldest message in queue
if [[ "$QUEUE_COUNT" -gt 0 ]]; then
    OLDEST=$(find /var/spool/postfix/deferred/ /var/spool/postfix/active/ -type f 2>/dev/null | \
        xargs ls -t 2>/dev/null | tail -1)
    if [[ -n "$OLDEST" ]]; then
        OLDEST_AGE=$(( ($(date +%s) - $(stat -c %Y "$OLDEST")) / 3600 ))
        [[ "$OLDEST_AGE" -gt 48 ]] && {
            warn "Oldest queued message: ${YEL}${OLDEST_AGE}h${RST} ago"
            rec "Stale queue msgs (${OLDEST_AGE}h) — consider: postsuper -d ALL deferred"
        }
    fi
fi

# ============================================================
# 7. BRUTE FORCE (time-filtered)
# ============================================================
hdr "BRUTE FORCE — last ${HOURS}h"

BF_TMP=$(grep "authentication failed" "$FILTERED_LOG" 2>/dev/null | \
    grep -oP 'unknown\[\K[0-9.]+' | sort | uniq -c | sort -rn | head -10)

if [[ -z "$BF_TMP" ]]; then
    ok "No brute force attempts found"
else
    TOTAL_BF=$(gcount "authentication failed" "$FILTERED_LOG" 2>/dev/null)
    if [[ "$TOTAL_BF" -gt 100 ]]; then
        fail "Total failed auth: ${RED}${TOTAL_BF}${RST}"
        rec "High brute force (${TOTAL_BF}) — tighten fail2ban bantime/findtime"
    elif [[ "$TOTAL_BF" -gt 20 ]]; then
        warn "Total failed auth: ${YEL}${TOTAL_BF}${RST}"
    else
        info "Total failed auth: ${TOTAL_BF}"
    fi
    echo -e "\n  ${DIM}Count   IP${RST}"
    echo "$BF_TMP" | while read -r COUNT IP; do
        if [[ "$COUNT" -gt 50 ]]; then echo -e "  ${RED}${COUNT}${RST}      ${IP}"
        elif [[ "$COUNT" -gt 10 ]]; then echo -e "  ${YEL}${COUNT}${RST}      ${IP}"
        else echo -e "  ${DIM}${COUNT}${RST}      ${IP}"; fi
    done
fi

# ============================================================
# 8. FAIL2BAN
# ============================================================
hdr "FAIL2BAN"

if ! command -v fail2ban-client &>/dev/null; then
    fail "fail2ban not found"
    rec "Install fail2ban: apt install fail2ban"
else
    TOTAL_BANNED=0
    for JAIL in postfix-sasl dovecot sshd recidive; do
        STATUS=$(fail2ban-client status "$JAIL" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            warn "Jail '${JAIL}' not found"
            [[ "$JAIL" == "recidive" ]] && rec "Enable recidive jail for repeat offenders"
            continue
        fi
        BANNED=$(echo "$STATUS" | grep "Currently banned" | awk '{print $NF}')
        FAILED=$(echo "$STATUS" | grep "Currently failed" | awk '{print $NF}')
        BANNED_IPS=$(echo "$STATUS" | grep "Banned IP list" | cut -d: -f2 | xargs)
        TOTAL_BANNED=$((TOTAL_BANNED + BANNED))
        if [[ "$BANNED" -gt 0 ]]; then
            warn "${JAIL}: ${YEL}${BANNED} banned${RST}, ${FAILED} failed | ${BANNED_IPS}"
        else
            ok "${JAIL}: ${BANNED} banned, ${FAILED} failed"
        fi
    done
    [[ "$TOTAL_BANNED" -gt 20 ]] && rec "High ban count (${TOTAL_BANNED}) — consider GeoIP blocking"
fi

# ============================================================
# 9. SECURITY HARDENING
# ============================================================
hdr "SECURITY HARDENING"

SSHD_CFG="/etc/ssh/sshd_config"
if [[ -f "$SSHD_CFG" ]]; then
    ROOT_LOGIN=$(grep -i "^PermitRootLogin" "$SSHD_CFG" 2>/dev/null | awk '{print $2}' | head -1)
    if [[ "$ROOT_LOGIN" == "no" || "$ROOT_LOGIN" == "prohibit-password" ]]; then
        ok "SSH: PermitRootLogin ${ROOT_LOGIN}"
    else
        warn "SSH: PermitRootLogin ${YEL}${ROOT_LOGIN:-yes (default)}${RST}"
        rec "SSH: set PermitRootLogin prohibit-password in sshd_config"
    fi

    PASS_AUTH=$(grep -i "^PasswordAuthentication" "$SSHD_CFG" 2>/dev/null | awk '{print $2}' | head -1)
    if [[ "$PASS_AUTH" == "no" ]]; then
        ok "SSH: PasswordAuth disabled (keys only)"
    else
        warn "SSH: PasswordAuth ${YEL}${PASS_AUTH:-yes (default)}${RST}"
        rec "SSH: set PasswordAuthentication no (use key auth only)"
    fi

    SSH_PORT=$(grep -i "^Port " "$SSHD_CFG" 2>/dev/null | awk '{print $2}' | head -1)
    [[ -n "$SSH_PORT" && "$SSH_PORT" != "22" ]] && ok "SSH: custom port ${SSH_PORT}" || \
        info "SSH: port 22 (default)"
fi

if dpkg -l unattended-upgrades 2>/dev/null | grep -q "^ii"; then
    ok "Unattended-upgrades: installed"
else
    warn "Unattended-upgrades: ${YEL}not installed${RST}"
    rec "Install unattended-upgrades for auto security patches"
fi

# Postfix: check smtpd_recipient_restrictions
RECIP_RESTRICT=$(postconf -h smtpd_recipient_restrictions 2>/dev/null)
if echo "$RECIP_RESTRICT" | grep -q "reject_unauth_destination"; then
    ok "Postfix: reject_unauth_destination is set (no open relay)"
else
    fail "Postfix: ${RED}reject_unauth_destination not found!${RST}"
    rec "CRITICAL: Add reject_unauth_destination to smtpd_recipient_restrictions"
fi

OPEN_PORTS=$(ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | grep -oP ':\K[0-9]+$' | sort -un | tr '\n' ' ')
info "Listening ports: ${DIM}${OPEN_PORTS}${RST}"

# ============================================================
# 10. RELAY STATUS
# ============================================================
hdr "RELAY STATUS"

RELAY=$(postconf -h relayhost 2>/dev/null)
if [[ -z "$RELAY" ]]; then
    info "Relay: ${DIM}disabled (direct send)${RST}"
else
    SASL_FILE="/etc/postfix/sasl_passwd"
    SASL_USER=$([[ -f "$SASL_FILE" ]] && awk '{print $2}' "$SASL_FILE" | cut -d: -f1 | head -1 || echo "unknown")
    ok "Relay: ${GRN}${RELAY}${RST} | user: ${SASL_USER}"
fi

# ============================================================
# 11. OUTGOING — top senders
# ============================================================
hdr "OUTGOING — top senders (all logs)"

echo -e "  ${DIM}Count   From${RST}"
SENDER_DATA=$(zgrep "sasl_username" "${MAIL_LOGS_ALL[@]}" 2>/dev/null | \
    grep -oP "sasl_username=\S+" | sed 's/sasl_username=//' | \
    sort | uniq -c | sort -rn | head -10)

if [[ -z "$SENDER_DATA" ]]; then
    info "No authenticated senders found"
else
    echo "$SENDER_DATA" | while read -r COUNT USER; do
        if [[ "$COUNT" -gt 500 ]]; then
            echo -e "  ${RED}${COUNT}${RST}      ${USER}  ${DIM}← high volume!${RST}"
        elif [[ "$COUNT" -gt 50 ]]; then
            echo -e "  ${GRN}${COUNT}${RST}      ${USER}"
        else
            echo -e "  ${DIM}${COUNT}${RST}      ${USER}"
        fi
    done
fi

# ============================================================
# 12. OUTGOING — top recipients
# ============================================================
hdr "OUTGOING — top recipients (all logs)"

echo -e "  ${DIM}Count   To (domain)${RST}"
RECIP_DATA=$(zgrep "status=sent" "${MAIL_LOGS_ALL[@]}" 2>/dev/null | \
    grep -oP 'to=<\K[^>]+' | awk -F@ '{print $2}' | \
    sort | uniq -c | sort -rn | head -10)

if [[ -z "$RECIP_DATA" ]]; then
    info "No sent messages found"
else
    echo "$RECIP_DATA" | while read -r COUNT DOMAIN_TO; do
        echo -e "  ${DIM}${COUNT}${RST}      ${DOMAIN_TO}"
    done
fi

# ============================================================
# 13. BOUNCED / DEFERRED (time-filtered)
# ============================================================
hdr "BOUNCED / DEFERRED — last ${HOURS}h"

BOUNCED=$(gcount "status=bounced" "$FILTERED_LOG" 2>/dev/null)
DEFERRED=$(gcount "status=deferred" "$FILTERED_LOG" 2>/dev/null)

if [[ "$BOUNCED" -gt 10 ]]; then
    fail "Bounced:  ${RED}${BOUNCED}${RST}"
    rec "High bounces (${BOUNCED}) — check sender reputation & recipient validity"
elif [[ "$BOUNCED" -gt 0 ]]; then
    warn "Bounced:  ${YEL}${BOUNCED}${RST}"
else
    ok "Bounced:  0"
fi

if [[ "$DEFERRED" -gt 10 ]]; then
    fail "Deferred: ${RED}${DEFERRED}${RST}"
    rec "Many deferred (${DEFERRED}) — check remote server connectivity"
elif [[ "$DEFERRED" -gt 0 ]]; then
    warn "Deferred: ${YEL}${DEFERRED}${RST}"
else
    ok "Deferred: 0"
fi

if [[ "$BOUNCED" -gt 0 ]]; then
    echo -e "\n  ${DIM}Top bounce reasons:${RST}"
    grep "status=bounced" "$FILTERED_LOG" 2>/dev/null | \
        grep -oP 'said: \K[^(]+' | sort | uniq -c | sort -rn | head -5 | \
        while read -r COUNT REASON; do
            echo -e "  ${RED}${COUNT}${RST}  ${DIM}${REASON}${RST}"
        done
fi

if [[ "$DEFERRED" -gt 0 ]]; then
    echo -e "\n  ${DIM}Top deferred reasons:${RST}"
    grep "status=deferred" "$FILTERED_LOG" 2>/dev/null | \
        grep -oP '\(.*\)' | sort | uniq -c | sort -rn | head -3 | \
        while read -r COUNT REASON; do
            echo -e "  ${YEL}${COUNT}${RST}  ${DIM}${REASON:0:100}${RST}"
        done
fi

# ============================================================
# 14. REJECTED INCOMING (time-filtered)
# ============================================================
hdr "REJECTED INCOMING — last ${HOURS}h"

REJECTED=$(gcount "NOQUEUE: reject" "$FILTERED_LOG" 2>/dev/null)
if [[ "$REJECTED" -gt 100 ]]; then
    warn "Total rejected: ${YEL}${REJECTED}${RST}"
elif [[ "$REJECTED" -gt 0 ]]; then
    info "Total rejected: ${REJECTED}"
else
    ok "No rejected incoming"
fi

if [[ "$REJECTED" -gt 0 ]]; then
    echo -e "\n  ${DIM}Top rejection reasons:${RST}"
    grep "NOQUEUE: reject" "$FILTERED_LOG" 2>/dev/null | \
        grep -oP 'reject: \K[^;]+' | sort | uniq -c | sort -rn | head -5 | \
        while read -r COUNT REASON; do
            echo -e "  ${YEL}${COUNT}${RST}  ${DIM}${REASON:0:80}${RST}"
        done
fi

# ============================================================
# 15. MAILBOXES
# ============================================================
hdr "MAILBOXES"

if [[ -d "$MAILBOX_DIR" ]]; then
    for DOM in "$MAILBOX_DIR"/*/; do
        [[ ! -d "$DOM" ]] && continue
        DNAME=$(basename "$DOM")
        DOM_SIZE=$(du -sh "$DOM" 2>/dev/null | awk '{print $1}')
        echo -e "\n  ${CYN}${DNAME}${RST} ${DIM}(${DOM_SIZE})${RST}"
        for BOX in "$DOM"*/; do
            [[ ! -d "$BOX" ]] && continue
            USER=$(basename "$BOX")
            BOX_SIZE=$(du -sh "$BOX" 2>/dev/null | awk '{print $1}')
            MSG_COUNT=$(find "$BOX" -type f \( -name "*,S=*" -o -name "*:2,*" \) 2>/dev/null | wc -l)
            LAST_FILE=$(find "$BOX" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $1}')
            LAST_DATE="no activity"
            [[ -n "$LAST_FILE" ]] && LAST_DATE=$(date -d "@${LAST_FILE%%.*}" '+%Y-%m-%d' 2>/dev/null || echo "?")

            SIZE_MB=$(du -sm "$BOX" 2>/dev/null | awk '{print $1}')
            if [[ "${SIZE_MB:-0}" -gt 5000 ]]; then
                echo -e "    ${RED}${USER}${RST}  ${RED}${BLD}${BOX_SIZE}${RST}  ${DIM}(~${MSG_COUNT} msgs, last: ${LAST_DATE})${RST}"
                rec "Mailbox ${USER}@${DNAME} is ${BOX_SIZE} — consider archiving"
            elif [[ "${SIZE_MB:-0}" -gt 1000 ]]; then
                echo -e "    ${YEL}${USER}${RST}  ${YEL}${BLD}${BOX_SIZE}${RST}  ${DIM}(~${MSG_COUNT} msgs, last: ${LAST_DATE})${RST}"
            else
                echo -e "    ${DIM}${USER}${RST}  ${BLD}${BOX_SIZE}${RST}  ${DIM}(~${MSG_COUNT} msgs, last: ${LAST_DATE})${RST}"
            fi
        done
    done
else
    warn "Mailbox dir not found: ${MAILBOX_DIR}"
fi

# ============================================================
# 16. BACKUP STATUS
# ============================================================
hdr "BACKUP STATUS"

BACKUP_DIR="/home/user-data/backup"
if [[ -d "$BACKUP_DIR" ]]; then
    LATEST_BACKUP=$(ls -td "$BACKUP_DIR"/encrypted/ "$BACKUP_DIR"/*/ 2>/dev/null | head -1)
    if [[ -n "$LATEST_BACKUP" ]]; then
        BACKUP_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")) / 86400 ))
        BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
        if [[ "$BACKUP_AGE" -gt 3 ]]; then
            fail "Last backup: ${RED}${BACKUP_AGE} days ago${RST} (${BACKUP_SIZE})"
            rec "Backup is ${BACKUP_AGE}d old — check backup config and cron"
        elif [[ "$BACKUP_AGE" -gt 1 ]]; then
            warn "Last backup: ${YEL}${BACKUP_AGE} days ago${RST} (${BACKUP_SIZE})"
        else
            ok "Last backup: today (${BACKUP_SIZE})"
        fi
    else
        warn "No backups found in ${BACKUP_DIR}"
        rec "Configure MIAB backups in admin panel"
    fi
else
    warn "Backup directory not found"
    rec "Verify backup configuration"
fi

# ============================================================
# RECOMMENDATIONS
# ============================================================
if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
    hdr "RECOMMENDATIONS"
    echo ""
    for i in "${!RECOMMENDATIONS[@]}"; do
        echo -e "  ${G2}$((i+1)).${RST} ${RECOMMENDATIONS[$i]}"
    done
fi

# ============================================================
# SUMMARY & FOOTER
# ============================================================
echo ""
echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"

TOTAL=$((COUNT_OK + COUNT_WARN + COUNT_FAIL))
echo -e "  ${BLD}SUMMARY${RST}: ${GRN}${COUNT_OK} OK${RST} / ${YEL}${COUNT_WARN} WARN${RST} / ${RED}${COUNT_FAIL} FAIL${RST}  (${TOTAL} checks)"

if [[ "$COUNT_FAIL" -gt 0 ]]; then
    echo -e "  ${RED}${BLD}⚡ Action required — ${COUNT_FAIL} issue(s) need attention${RST}"
elif [[ "$COUNT_WARN" -gt 0 ]]; then
    echo -e "  ${YEL}${BLD}⚡ Review recommended — ${COUNT_WARN} warning(s)${RST}"
else
    echo -e "  ${GRN}${BLD}✔ All checks passed${RST}"
fi

[[ ${#RECOMMENDATIONS[@]} -gt 0 ]] && \
    echo -e "  ${DIM}↑ ${#RECOMMENDATIONS[@]} recommendation(s) — scroll up to ══ RECOMMENDATIONS ══${RST}"

echo ""
echo -e "  ${G1}miab-radar${RST} ${DIM}v3.0${RST} ${DIM}|${RST} ${DIM}github.com/Anton-Babaskin/miab-radar${RST} ${DIM}|${RST} ${DIM}$(date '+%Y-%m-%d %H:%M')${RST}"
echo -e "  ${DIM}by ${G1}Anton Babaskin${RST} ${DIM}— suggestions, bugs? Open an issue on GitHub${RST}"
echo ""

# Exit code for cron/monitoring: 2=fail, 1=warn, 0=clean
[[ "$COUNT_FAIL" -gt 0 ]] && exit 2
[[ "$COUNT_WARN" -gt 0 ]] && exit 1
exit 0
