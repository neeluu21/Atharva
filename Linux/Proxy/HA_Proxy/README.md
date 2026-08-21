# HAProxy — Load Balancer & Reverse Proxy Setup & Documentation

A hands-on guide to configuring **HAProxy** for load balancing, high availability, and health-checked traffic routing across backend servers.

---

## Table of Contents

1. [What Is HAProxy](#what-is-haproxy)
2. [HAProxy vs Nginx](#haproxy-vs-nginx)
3. [Architecture](#architecture)
4. [Prerequisites](#prerequisites)
5. [Installation](#installation)
6. [Basic Load Balancer Configuration](#basic-load-balancer-configuration)
7. [Load Balancing Algorithms](#load-balancing-algorithms)
8. [Health Checks](#health-checks)
9. [SSL/TLS Termination](#ssltls-termination)
10. [The HAProxy Stats Dashboard](#the-haproxy-stats-dashboard)
11. [High Availability with Keepalived](#high-availability-with-keepalived)
12. [Testing the Setup](#testing-the-setup)
13. [Troubleshooting](#troubleshooting)
14. [Project Structure for This Repo](#project-structure-for-this-repo)

---

## What Is HAProxy

HAProxy sits between clients and a pool of backend servers, distributing incoming connections across them. It operates at:

- **Layer 4 (TCP)** — routes raw connections without inspecting HTTP content (fast, protocol-agnostic)
- **Layer 7 (HTTP)** — inspects headers, cookies, and URLs to make routing decisions (e.g., route `/api` differently from `/static`)

```
Client ──▶ HAProxy ──▶ Backend Server 1
                   ├──▶ Backend Server 2
                   └──▶ Backend Server 3
```

It continuously health-checks backends and automatically stops routing traffic to any that go down — this is the "High Availability" part of the name.

### Common use cases
- Distributing traffic across multiple app servers
- Automatic failover when a backend dies
- SSL termination at the edge
- Rate limiting and connection throttling
- Blue-green / canary deployment routing

---

## HAProxy vs Nginx

| | HAProxy | Nginx |
|---|---|---|
| Primary purpose | Load balancing | Web server + reverse proxy |
| Layer 4 (TCP) support | Excellent, native | Limited (stream module) |
| Layer 7 (HTTP) routing | Excellent | Excellent |
| Health checks | Built-in, very granular | Basic (needs `nginx_upstream_check_module` for advanced) |
| Stats dashboard | Built-in web UI | Requires third-party module |
| Serving static files | Not designed for this | Very good |
| Typical role | Sits in front of app servers as pure LB | Often does both LB and static file serving |

**In practice:** many production setups use both — Nginx serving static assets and terminating some traffic, HAProxy distributing dynamic requests across app server pools. Knowing both, and *why* you'd pick one over the other, is what interviewers actually want to hear.

---

## Architecture

```
                    ┌───────────────────────────┐
Internet ── :443 ──▶│   HAProxy                 │
                    │   - Health checks          │
                    │   - Load balancing         │
                    │   - SSL termination        │
                    │   - Stats dashboard :8404  │
                    └────────────┬────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
       App Server 1       App Server 2       App Server 3
       (port 3000)        (port 3001)        (port 3002)
       [health check]     [health check]     [health check — DOWN, auto-removed]
```

---

## Prerequisites

- Linux server (Ubuntu 22.04/24.04 used here)
- `sudo` access
- 2+ backend app instances to load balance across (can be the same app running on different ports for testing)

---

## Installation

```bash
sudo apt update
sudo apt install haproxy -y

# Check version
haproxy -v

# Enable + start
sudo systemctl enable haproxy
sudo systemctl start haproxy
sudo systemctl status haproxy
```

Key file locations:

| Path | Purpose |
|---|---|
| `/etc/haproxy/haproxy.cfg` | Main (and usually only) config file |
| `/var/log/haproxy.log` | Logs (may need rsyslog config to populate) |

---

## Basic Load Balancer Configuration

Edit the config:

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

A minimal working config:

```haproxy
global
    log /dev/log local0
    maxconn 2000
    daemon

defaults
    log     global
    mode    http
    timeout connect 5s
    timeout client  50s
    timeout server  50s

frontend http_front
    bind *:80
    default_backend app_servers

backend app_servers
    balance roundrobin
    option httpchk GET /health
    server app1 127.0.0.1:3000 check
    server app2 127.0.0.1:3001 check
    server app3 127.0.0.1:3002 check
```

**Structure explained:**
- `global` — process-wide settings (logging, connection limits)
- `defaults` — shared settings inherited by frontends/backends
- `frontend` — where HAProxy listens for incoming traffic
- `backend` — the pool of servers traffic gets routed to

Apply the config:

```bash
# Validate syntax before reloading — always do this
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload
sudo systemctl reload haproxy
```

---

## Load Balancing Algorithms

Set via `balance <algorithm>` in the backend block:

| Algorithm | Behavior |
|---|---|
| `roundrobin` | Requests rotate evenly across servers (default, good general choice) |
| `leastconn` | Sends to the server with the fewest active connections (good for long-lived connections) |
| `source` | Same client IP always hits the same server (session persistence without cookies) |
| `uri` | Routes based on request URI — useful for cache-friendly routing |
| `static-rr` | Weighted round robin, static weight per server |

Example with weights (server gets traffic proportional to `weight`):

```haproxy
backend app_servers
    balance roundrobin
    server app1 127.0.0.1:3000 check weight 3
    server app2 127.0.0.1:3001 check weight 1
```

Here `app1` gets ~3x the traffic of `app2` — useful when servers have different capacity.

---

## Health Checks

HAProxy's built-in health checking is one of its strongest features — it removes dead servers from rotation automatically.

```haproxy
backend app_servers
    option httpchk GET /health
    http-check expect status 200

    server app1 127.0.0.1:3000 check inter 2000 rise 2 fall 3
    server app2 127.0.0.1:3001 check inter 2000 rise 2 fall 3
```

| Parameter | Meaning |
|---|---|
| `check` | Enables health checking for this server |
| `inter 2000` | Check every 2000ms |
| `rise 2` | Mark server "up" after 2 consecutive successful checks |
| `fall 3` | Mark server "down" after 3 consecutive failed checks |

Your backend app needs a `/health` endpoint that returns HTTP 200 when healthy — this is a good thing to add to any app you build.

---

## SSL/TLS Termination

Combine your cert and key into a single `.pem` file (HAProxy requires this format):

```bash
sudo cat yourdomain.crt yourdomain.key > /etc/haproxy/certs/yourdomain.pem
```

Config:

```haproxy
frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/yourdomain.pem
    default_backend app_servers

frontend http_front
    bind *:80
    redirect scheme https code 301 if !{ ssl_fc }
```

For free certs, generate with Certbot in standalone mode first (`certbot certonly --standalone`), then combine the resulting `fullchain.pem` and `privkey.pem` as shown above. You'll need to re-combine and reload after each renewal — consider a small renewal hook script for this.

---

## The HAProxy Stats Dashboard

HAProxy ships with a built-in web dashboard showing live backend status, request counts, and response times — great for demos and screenshots in your portfolio.

```haproxy
frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:yourpassword
```

Visit `http://your_server_ip:8404/stats` and log in to see live server health, session counts, and error rates per backend.

---

## High Availability with Keepalived

HAProxy itself is a single point of failure unless you run more than one instance. **Keepalived** provides a floating "virtual IP" that fails over between two HAProxy nodes:

```bash
sudo apt install keepalived -y
```

`/etc/keepalived/keepalived.conf` on the primary node:

```
vrrp_script chk_haproxy {
    script "killall -0 haproxy"
    interval 2
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101
    virtual_ipaddress {
        192.168.1.100
    }
    track_script {
        chk_haproxy
    }
}
```

On a secondary node, set `state BACKUP` and `priority 100` (lower than the primary). If the primary's HAProxy process dies, the virtual IP automatically moves to the backup — this is what makes the setup genuinely "highly available" rather than just load-balanced.

---

## Testing the Setup

```bash
# Validate config
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Confirm it's listening
sudo ss -tulpn | grep haproxy

# Send test requests and observe round-robin behavior
for i in {1..6}; do curl -s http://localhost/whoami; echo; done

# Watch logs
sudo tail -f /var/log/haproxy.log
```

To make round-robin visible, have each backend instance return its own identity (e.g., `PORT=3000 node server.js` printing `"Hello from server on 3000"`).

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| `503 Service Unavailable` | All backends failing health checks | Check backend app logs, confirm `/health` endpoint returns 200 |
| Config won't reload | Syntax error | Run `haproxy -c -f /etc/haproxy/haproxy.cfg` for the exact line |
| Traffic not balancing | Only one healthy backend, or `source`/`ip_hash`-style persistence in use | Check stats dashboard for backend status |
| Stats page not loading | Firewall blocking port 8404 | `sudo ufw allow 8404` |
| SSL handshake failures | `.pem` missing key or wrong order | Cert must come before key in the combined file |

---

## Project Structure for This Repo

```
haproxy-load-balancer/
├── README.md                  <- this file
├── configs/
│   ├── basic-lb.cfg
│   ├── ssl-termination.cfg
│   └── stats-dashboard.cfg
├── keepalived/
│   └── keepalived.conf
└── screenshots/
    └── stats-dashboard.png
```

---

## References

- [Official HAProxy Documentation](https://www.haproxy.org/#docs)
- [HAProxy Configuration Manual](https://docs.haproxy.org/)
- [Keepalived Documentation](https://www.keepalived.org/)
