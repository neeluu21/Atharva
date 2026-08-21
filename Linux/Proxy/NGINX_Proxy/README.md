# Nginx Reverse Proxy — Setup & Documentation

A hands-on guide to configuring **Nginx as a reverse proxy** for a backend application, including SSL termination, load balancing, and production-ready best practices.

---

## Table of Contents

1. [What Is a Reverse Proxy](#what-is-a-reverse-proxy)
2. [Why Use Nginx](#why-use-nginx)
3. [Architecture](#architecture)
4. [Prerequisites](#prerequisites)
5. [Installation](#installation)
6. [Basic Reverse Proxy Configuration](#basic-reverse-proxy-configuration)
7. [Load Balancing Multiple Backends](#load-balancing-multiple-backends)
8. [SSL/TLS Termination (HTTPS)](#ssltls-termination-https)
9. [Caching Static Content](#caching-static-content)
10. [Security Hardening](#security-hardening)
11. [Testing the Setup](#testing-the-setup)
12. [Troubleshooting](#troubleshooting)
13. [Project Structure for This Repo](#project-structure-for-this-repo)

---

## What Is a Reverse Proxy

A **reverse proxy** is a server that sits between clients and your backend server(s). Instead of clients talking directly to your application, they talk to Nginx, and Nginx forwards the request to the right backend.

```
Client  --->  Nginx (Reverse Proxy)  --->  Backend App (Node/Python/Java/etc.)
                     |
                     ---> Backend App 2 (for load balancing)
                     ---> Backend App 3
```

This is different from a **forward proxy**, which sits in front of *clients* (e.g., a corporate proxy hiding employee identities from the internet). A reverse proxy hides the *server's* identity and structure from the client.

### Common use cases
- **Load balancing** — distribute traffic across multiple backend instances
- **SSL/TLS termination** — handle HTTPS at the proxy, keep backend on plain HTTP
- **Caching** — serve repeated requests without hitting the backend
- **Security** — hide internal server details, rate-limit, block malicious requests
- **Single entry point** — route `/api` to one service and `/` to another, all on port 80/443

---

## Why Use Nginx

- Extremely lightweight and fast (event-driven, non-blocking architecture)
- Handles thousands of concurrent connections with low memory usage
- Widely used in production (used by a large share of high-traffic websites)
- Doubles as a web server, load balancer, and reverse proxy in one binary
- Simple, declarative configuration syntax

---

## Architecture

```
                         ┌───────────────────────┐
  Internet  ── HTTPS ──▶ │   Nginx (port 443)    │
                         │   - SSL termination   │
                         │   - Reverse proxy     │
                         │   - Load balancing    │
                         └──────────┬─────────────┘
                                    │ HTTP (internal)
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
             App Server 1    App Server 2    App Server 3
             (port 3000)     (port 3000)     (port 3000)
```

In this repo's example, we'll proxy requests to a simple backend running on `localhost:3000`.

---

## Prerequisites

- A Linux server (Ubuntu 22.04/24.04 used in examples) — a VM, cloud instance (EC2/DigitalOcean), or local machine
- `sudo` access
- A backend application running on some local port (e.g., `3000`) — any stack works (Node.js, Flask, Django, Spring Boot)
- (Optional) A domain name pointed at your server's IP, for the SSL section

---

## Installation

```bash
# Update package list
sudo apt update

# Install Nginx
sudo apt install nginx -y

# Start and enable on boot
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

Verify it's running by visiting `http://<server-ip>` — you should see the default Nginx welcome page.

Key file locations:

| Path | Purpose |
|---|---|
| `/etc/nginx/nginx.conf` | Main config file |
| `/etc/nginx/sites-available/` | Where you define individual site configs |
| `/etc/nginx/sites-enabled/` | Symlinks to active configs from `sites-available` |
| `/var/log/nginx/access.log` | Request logs |
| `/var/log/nginx/error.log` | Error logs |

---

## Basic Reverse Proxy Configuration

Create a new config file for your site:

```bash
sudo nano /etc/nginx/sites-available/myapp
```

Paste this configuration:

```nginx
server {
    listen 80;
    server_name your_domain_or_ip;

    location / {
        proxy_pass         http://localhost:3000;
        proxy_http_version 1.1;

        # Pass along useful headers so the backend knows the real client info
        proxy_set_header    Host              $host;
        proxy_set_header    X-Real-IP         $remote_addr;
        proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto $scheme;

        # WebSocket support (optional, needed for apps using sockets)
        proxy_set_header    Upgrade           $http_upgrade;
        proxy_set_header    Connection        "upgrade";
    }
}
```

Enable the site and disable the default one:

```bash
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test config syntax before reloading
sudo nginx -t

# Reload Nginx to apply changes
sudo systemctl reload nginx
```

Now requests to `http://your_domain_or_ip/` are forwarded to your backend on port `3000`, while the client only ever sees Nginx.

---

## Load Balancing Multiple Backends

If you're running multiple instances of your app (e.g., for scaling), define an `upstream` block:

```nginx
upstream backend_servers {
    least_conn;                      # load balancing method (see below)
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
    server 127.0.0.1:3002;
}

server {
    listen 80;
    server_name your_domain_or_ip;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Load balancing methods:**

| Method | Behavior |
|---|---|
| `round_robin` (default) | Requests distributed evenly in order |
| `least_conn` | Sends request to the server with fewest active connections |
| `ip_hash` | Same client IP always goes to the same backend (session persistence) |

---

## SSL/TLS Termination (HTTPS)

The easiest way is **Let's Encrypt** with Certbot (free, auto-renewing certificates):

```bash
sudo apt install certbot python3-certbot-nginx -y

# Certbot auto-edits your Nginx config to add SSL
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

Certbot will produce a config similar to:

```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$host$request_uri;   # redirect HTTP to HTTPS
}
```

---

## Caching Static Content

Offload static assets so the backend isn't hit for every image/CSS/JS file:

```nginx
location ~* \.(jpg|jpeg|png|gif|css|js|ico|svg)$ {
    proxy_pass http://localhost:3000;
    proxy_cache_valid 200 60m;
    expires 30d;
    add_header Cache-Control "public, no-transform";
}
```

For proxy-level caching (caches full responses on disk), add this near the top of `nginx.conf`, inside the `http` block:

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;
```

Then reference `my_cache` inside a `location` block with `proxy_cache my_cache;`.

---

## Security Hardening

```nginx
# Hide Nginx version in headers/errors
server_tokens off;

# Limit request size (prevents large payload abuse)
client_max_body_size 10M;

# Basic rate limiting (place in http block)
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;

server {
    location / {
        limit_req zone=mylimit burst=20 nodelay;
        proxy_pass http://localhost:3000;
    }
}
```

Other recommendations:
- Keep Nginx updated (`sudo apt update && sudo apt upgrade nginx`)
- Only expose ports 80/443 publicly; keep backend ports firewalled (`ufw deny 3000`)
- Use `fail2ban` to block repeated malicious requests
- Disable directory listing (`autoindex off;` — it's off by default)

---

## Testing the Setup

```bash
# Check config syntax
sudo nginx -t

# Check which ports Nginx is listening on
sudo ss -tulpn | grep nginx

# Send a test request
curl -I http://localhost

# Watch logs live while testing
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

If you set up load balancing, add a distinct log line or response header per backend instance so you can confirm requests are actually being distributed.

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| `502 Bad Gateway` | Backend app isn't running or wrong port | Check `systemctl status` of backend, confirm `proxy_pass` port |
| `nginx -t` fails | Syntax error in config | Read the line number in the error, check for missing `;` or `{}` |
| Changes not applying | Forgot to reload | `sudo systemctl reload nginx` |
| Permission denied errors in logs | SELinux/AppArmor blocking | Check `sudo journalctl -u nginx` |
| WebSocket connections drop | Missing upgrade headers | Add `Upgrade`/`Connection` headers shown above |

---

## Project Structure for This Repo

Suggested layout when you upload this to GitHub:

```
nginx-reverse-proxy/
├── README.md                  <- this file
├── configs/
│   ├── basic-proxy.conf
│   ├── load-balancer.conf
│   └── ssl-proxy.conf
├── docker/
│   └── docker-compose.yml     <- optional: spin up nginx + backend for demo
└── screenshots/
    └── curl-test-output.png
```

This structure signals to anyone reviewing your GitHub (including recruiters) that you understand config organization, not just a single copy-pasted file.

---

## References

- [Official Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Certbot](https://certbot.eff.org/)
