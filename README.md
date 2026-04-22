# miab-radar

<p align="center">
  <b>Production-grade Mail-in-a-Box monitoring & audit tool</b>
</p>

<p align="center">
  Deep visibility into mail server health, deliverability, and security — directly from your terminal.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/bash-4%2B-blue">
  <img src="https://img.shields.io/badge/status-active-success">
  <img src="https://img.shields.io/badge/license-MIT-green">
</p>

---

## Overview

**miab-radar** is a high-signal diagnostic and monitoring tool for Mail-in-a-Box servers.

It goes far beyond basic status checks by analyzing:

* real mail logs
* delivery behavior
* DNS configuration
* blacklist status
* security posture

Designed for sysadmins and DevOps engineers who want **actionable insights**, not noise.

---

## Key Features

### Mail & Deliverability

* Mail queue inspection (active / deferred / stuck)
* Bounce & deferred analysis (with reasons)
* Top senders and recipients
* SMTP flow visibility

### DNS & Reputation

* SPF / DKIM / DMARC validation
* PTR (reverse DNS) verification
* Blacklist checks:

  * Spamhaus (ZEN, DBL)
  * Spamcop
  * Barracuda
  * SORBS

### Security

* Brute-force detection from logs
* Fail2Ban status (per jail)
* SSH hardening checks
* Open relay protection validation

### TLS & Encryption

* Certificate validity checks (SMTP, IMAPS, HTTPS)
* Expiration alerts
* STARTTLS verification

### System Health

* Service monitoring (Postfix, Dovecot, Nginx, etc.)
* Disk & inode usage
* Mailbox size analysis
* Backup freshness validation

### Smart Output

* Clear OK / WARN / FAIL classification
* Prioritized recommendations
* Exit codes for automation

---

## Example Output

See real output:

```
examples/output.txt
```

---

## Installation

Clone the repository:

```
git clone https://github.com/YOUR_USERNAME/miab-radar.git
cd miab-radar
chmod +x miab-radar.sh
```

Optional global install:

```
sudo ./install.sh
```

---

## Usage

Run full audit:

```
sudo ./miab-radar.sh
```

Specify time window (in hours):

```
sudo ./miab-radar.sh 48
```

---

## Automation (Cron)

Run every 30 minutes:

```
*/30 * * * * /usr/local/bin/miab-radar > /var/log/miab-radar.log
```

---

## Exit Codes

| Code | Meaning                  |
| ---- | ------------------------ |
| 0    | All checks passed        |
| 1    | Warnings present         |
| 2    | Critical issues detected |

---

## Why miab-radar

Mail-in-a-Box provides only surface-level diagnostics.

miab-radar adds:

* deep log analysis
* deliverability troubleshooting
* security auditing
* precise, actionable fixes

This makes it suitable for **production environments**, not just hobby setups.

---

## Architecture Philosophy

miab-radar follows a simple but powerful model:

* Bash → deterministic checks
* Logs → source of truth
* Output → actionable insights

No heavy dependencies. No agents. No overhead.

---

## Requirements

* Ubuntu / Debian
* Root access
* Mail-in-a-Box installed

---

## Roadmap

* JSON output mode (for integrations)
* Telegram / Slack alerts
* Prometheus exporter
* Historical metrics tracking
* AI-based anomaly detection

---

## Contributing

Pull requests are welcome.

Guidelines:

* keep it simple
* keep it readable
* avoid unnecessary dependencies
* focus on real-world usefulness

---

## License

MIT License

---

## Author

Anton Babaskin

---

## Final Note

If you run your own mail server — you need visibility.

miab-radar gives you exactly that.
