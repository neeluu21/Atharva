# Nginx Load Balancer Troubleshooting Guide

## 1. Browser Shows "Welcome to nginx!"

### Problem

You still see the default Nginx page.

### Check

```bash
ls -l /etc/nginx/sites-enabled/
```

If you see:

```text
default
```

remove it:

```bash
sudo rm -f /etc/nginx/sites-enabled/default
```

Check your load-balancer file:

```bash
ls -l /etc/nginx/sites-enabled/
```

You should see:

```text
loadbalance
```

Then:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

# 2. `curl localhost:3000` Does Not Work

Check:

```bash
sudo ss -lntp | grep 3000
```

If nothing appears, Backend 1 is not running.

Start it:

```bash
cd /var/www/backend1
python3 -m http.server 3000 --bind 127.0.0.1
```

Test:

```bash
curl http://127.0.0.1:3000
```

---

# 3. `curl localhost:4000` Does Not Work

Check:

```bash
sudo ss -lntp | grep 4000
```

Start Backend 2:

```bash
cd /var/www/backend2
python3 -m http.server 4000 --bind 127.0.0.1
```

Test:

```bash
curl http://127.0.0.1:4000
```

---

# 4. Nginx Configuration Error

Run:

```bash
sudo nginx -t
```

If you get an error, inspect the exact file:

```bash
sudo nano /etc/nginx/sites-available/loadbalance
```

Then test again:

```bash
sudo nginx -t
```

Do not reload Nginx until the test succeeds.

---

# 5. Nginx Is Not Running

Check:

```bash
sudo systemctl status nginx
```

Start:

```bash
sudo systemctl start nginx
```

If it fails:

```bash
sudo journalctl -u nginx --no-pager -n 50
```

---

# 6. Port 80 Is Not Listening

Run:

```bash
sudo ss -lntp | grep ':80'
```

If there is no output:

```bash
sudo systemctl restart nginx
```

Then:

```bash
sudo ss -lntp | grep ':80'
```

---

# 7. Browser Shows Connection Timeout

This is usually an AWS networking issue.

Check the EC2 Security Group.

Inbound rule must contain:

```text
HTTP
TCP
80
0.0.0.0/0
```

You do not need to expose ports 3000 and 4000 for this architecture.

Also verify the instance has a public IPv4 address.

---

# 8. Browser Shows 502 Bad Gateway

This usually means Nginx cannot reach a backend.

Test:

```bash
curl http://127.0.0.1:3000
curl http://127.0.0.1:4000
```

Check Nginx error log:

```bash
sudo tail -f /var/log/nginx/loadbalance_error.log
```

Check ports:

```bash
sudo ss -lntp | grep -E '3000|4000'
```

---

# 9. Backend Is Running But Nginx Cannot Connect

Check the upstream configuration:

```bash
sudo nginx -T
```

Look for:

```nginx
upstream backend_servers {
    server 127.0.0.1:3000;
    server 127.0.0.1:4000;
}
```

Make sure the ports match the actual Python servers.

---

# 10. Browser Shows Only Backend 1

This can happen during testing if requests are cached or if the backend selection is not obvious.

Use curl:

```bash
for i in {1..20}; do
    curl -s http://127.0.0.1 | grep "Backend Server"
done
```

Also watch logs:

```bash
sudo tail -f /var/log/nginx/loadbalance_access.log
```

---

# 11. Backend Python Server Stops

`python3 -m http.server` is mainly useful for a learning lab.

For production-style practice, use:

- systemd
- Docker
- Node.js with PM2
- Kubernetes
- AWS services

For this practical, restarting the Python server is enough.

---

# 12. Port Already in Use

Example:

```text
OSError: [Errno 98] Address already in use
```

Find the process:

```bash
sudo ss -lntp | grep 3000
```

or:

```bash
sudo ss -lntp | grep 4000
```

Find the PID:

```bash
sudo lsof -i :3000
sudo lsof -i :4000
```

Stop the unwanted process:

```bash
sudo kill PID
```

---

# 13. Nginx Default Configuration Still Appears

Check:

```bash
sudo nginx -T
```

Search for:

```text
Welcome to nginx
```

If the default server is still enabled:

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

---

# 14. Check Nginx Processes

```bash
pidof nginx
```

or:

```bash
ps aux | grep nginx
```

You normally see one master process and worker processes.

---

# 15. Check All Required Ports

```bash
sudo ss -lntp
```

Expected:

```text
:80
:3000
:4000
```

Example:

```text
127.0.0.1:3000
127.0.0.1:4000
0.0.0.0:80
```

---

# 16. Check Backend Files

```bash
ls -la /var/www/backend1
ls -la /var/www/backend2
```

Expected:

```text
index.html
```

Test:

```bash
cat /var/www/backend1/index.html
cat /var/www/backend2/index.html
```

---

# 17. Test the Complete Path

### Backend 1

```bash
curl http://127.0.0.1:3000
```

### Backend 2

```bash
curl http://127.0.0.1:4000
```

### Nginx

```bash
curl http://127.0.0.1
```

### Public IP

```bash
curl http://YOUR_EC2_PUBLIC_IP
```

### Browser

```text
http://YOUR_EC2_PUBLIC_IP
```

If the first two work but Nginx does not, investigate Nginx.

If Nginx works with localhost but the browser cannot connect, investigate AWS Security Group/public networking.

---

# 18. Useful Diagnostic Command Set

Run these when asking for help:

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo ss -lntp
curl -I http://127.0.0.1
curl -I http://127.0.0.1:3000
curl -I http://127.0.0.1:4000
ls -l /etc/nginx/sites-enabled/
sudo tail -n 30 /var/log/nginx/loadbalance_error.log
```

These commands provide most of the information needed to identify common problems.
