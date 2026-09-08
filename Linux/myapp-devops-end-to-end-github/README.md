# Full-Stack Student Management System — DevOps Deployment

End-to-end deployment of a React/Vite frontend, Node.js/Express backend, MongoDB database, Nginx reverse proxy, AWS S3 application-data integration, and automated MongoDB backups to S3.

## Architecture

```text
Browser
   |
   v
Nginx :80
   |
   +--> React/Vite static files
   |
   +--> /api/* --> Node.js/Express :5000
                         |
                         +--> MongoDB :27017
                         |
                         +--> AWS S3 (application data)

MongoDB
   |
   +--> mongodump + gzip
            |
            v
        AWS S3 backup
            ^
            |
          Cron
```

## Main components

- Ubuntu EC2
- Nginx
- React + Vite
- Node.js + Express
- MongoDB
- Mongoose
- AWS S3
- AWS CLI
- MongoDB `mongodump` / `mongorestore`
- systemd
- Cron

## Project structure

```text
myapp/
├── frontend/
│   ├── src/
│   ├── package.json
│   └── dist/
├── backend/
│   ├── server.js
│   ├── package.json
│   └── .env
├── nginx/
│   └── myapp.conf
├── systemd/
│   └── myapp-backend.service
├── backup/
│   └── mongodb-s3-backup.sh
└── README.md
```

## Deployment order

1. Prepare Ubuntu server
2. Install Node.js, Nginx and MongoDB
3. Upload application
4. Configure backend and MongoDB
5. Build frontend
6. Configure Nginx reverse proxy
7. Run backend with systemd
8. Configure EC2 IAM role and S3
9. Configure MongoDB backup to S3
10. Schedule backup with Cron
11. Test application, backup and restore
12. Apply security checks

---

# 1. Server preparation

```bash
sudo apt update
sudo apt upgrade -y

sudo apt install -y nginx curl git unzip
```

Check:

```bash
nginx -v
curl --version
git --version
```

Create project directory:

```bash
sudo mkdir -p /var/www/myapp
sudo chown -R $USER:$USER /var/www/myapp
```

---

# 2. Install Node.js

Use the Node.js version appropriate for your application. Example using NodeSource:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

Verify:

```bash
node -v
npm -v
```

---

# 3. Install MongoDB

Install MongoDB using the official MongoDB repository for the Ubuntu release running on your server.

After installation:

```bash
sudo systemctl enable --now mongod
sudo systemctl status mongod --no-pager
```

Verify:

```bash
mongosh --eval 'db.runCommand({ ping: 1 })'
```

MongoDB should normally listen only on localhost/private interfaces. Do not expose port `27017` to the internet.

---

# 4. Backend setup

```bash
cd /var/www/myapp/backend
npm install
```

Copy the example file and fill in your own values:

```bash
cp .env.example .env
nano .env
```

`.env.example` (already included in this repo, safe to commit):

```env
PORT=5000
MONGODB_URI=mongodb://127.0.0.1:27017/studentdb
AWS_REGION=ap-south-1
S3_BUCKET_NAME=YOUR_BUCKET_NAME
```

Never commit the real `.env` file or AWS credentials to GitHub — it's already excluded in `.gitignore`.

Test backend:

```bash
node server.js
```

In another terminal:

```bash
curl http://127.0.0.1:5000/api/health
```

Expected:

```json
{
  "success": true,
  "message": "Student API is running successfully"
}
```

Stop the manual process with `Ctrl+C` after testing.

---

# 5. Backend systemd service

Create:

```bash
sudo nano /etc/systemd/system/myapp-backend.service
```

Use:

```ini
[Unit]
Description=MyApp Node.js Backend
After=network.target mongod.service
Wants=mongod.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/var/www/myapp/backend
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /var/www/myapp/backend/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

If your Linux username is not `ubuntu`, replace `User=ubuntu`.

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp-backend
sudo systemctl start myapp-backend
```

Check:

```bash
sudo systemctl status myapp-backend --no-pager
```

Logs:

```bash
sudo journalctl -u myapp-backend -f
```

Verify:

```bash
curl http://127.0.0.1:5000/api/health
```

---

# 6. Frontend setup

```bash
cd /var/www/myapp/frontend
npm install
npm run build
```

Check:

```bash
ls -la dist/
```

The production frontend should be available under:

```text
/var/www/myapp/frontend/dist
```

---

# 7. Nginx reverse proxy

Create:

```bash
sudo nano /etc/nginx/sites-available/myapp
```

Configuration:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name _;

    root /var/www/myapp/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable:

```bash
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/myapp
```

If the link already exists, do not create it again.

Remove the default site if required:

```bash
sudo rm -f /etc/nginx/sites-enabled/default
```

Test:

```bash
sudo nginx -t
```

Reload:

```bash
sudo systemctl reload nginx
```

Check:

```bash
sudo systemctl status nginx --no-pager
```

---

# 8. Test the application

Backend directly:

```bash
curl http://127.0.0.1:5000/api/health
```

Backend through Nginx:

```bash
curl http://127.0.0.1/api/health
```

Get students:

```bash
curl http://127.0.0.1/api/students
```

Create a student:

```bash
curl -X POST http://127.0.0.1/api/students   -H "Content-Type: application/json"   -d '{"name":"Neel","email":"neel@example.com","course":"BSc IT"}'
```

Then:

```bash
curl http://127.0.0.1/api/students
```

Open:

```text
http://YOUR_EC2_PUBLIC_IP/
```

---

# 9. AWS S3 application-data integration

Create an S3 bucket in your required AWS region.

Recommended security:

- Keep the bucket private.
- Use an EC2 IAM role instead of hard-coded AWS access keys.
- Grant only the required S3 permissions.

Example permissions:

```text
s3:PutObject
s3:GetObject
s3:ListBucket
```

Limit access to the required bucket/prefix where possible.

Install the AWS SDK in the backend:

```bash
cd /var/www/myapp/backend
npm install @aws-sdk/client-s3
```

The backend can use the EC2 instance role automatically through the AWS SDK credential provider chain.

After changing backend code:

```bash
sudo systemctl restart myapp-backend
sudo systemctl status myapp-backend --no-pager
```

---

# 10. MongoDB backup configuration

Create backup directory:

```bash
sudo mkdir -p /var/backups/mongodb
sudo chown -R ubuntu:ubuntu /var/backups/mongodb
```

Check required commands:

```bash
which mongodump
which mongorestore
which aws
```

If AWS CLI is missing:

```bash
sudo apt install -y awscli
```

Verify:

```bash
aws --version
```

---

# 11. Backup script

Create:

```bash
sudo nano /usr/local/bin/mongodb-s3-backup.sh
```

Use:

```bash
#!/bin/bash

set -e

DB_NAME="studentdb"
BACKUP_DIR="/var/backups/mongodb"
S3_BUCKET="YOUR_BUCKET_NAME"
S3_PATH="mongodb-backups"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${DB_NAME}_${TIMESTAMP}.archive.gz"
LOCAL_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
LOG_FILE="/var/log/mongodb-s3-backup.log"

echo "========================================" >> "$LOG_FILE"
echo "Backup started: $(date)" >> "$LOG_FILE"

echo "Creating MongoDB backup..." >> "$LOG_FILE"

/usr/bin/mongodump     --db="$DB_NAME"     --archive="$LOCAL_FILE"     --gzip

echo "MongoDB backup created: $LOCAL_FILE" >> "$LOG_FILE"

echo "Uploading backup to S3..." >> "$LOG_FILE"

/usr/bin/aws s3 cp     "$LOCAL_FILE"     "s3://${S3_BUCKET}/${S3_PATH}/${BACKUP_FILE}"

echo "Backup uploaded to S3 successfully." >> "$LOG_FILE"

find "$BACKUP_DIR"     -type f     -name "*.archive.gz"     -mtime +7     -delete

echo "Old local backups cleaned." >> "$LOG_FILE"
echo "Backup completed: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
```

Replace:

```text
YOUR_BUCKET_NAME
```

with your actual private S3 bucket.

Make executable:

```bash
sudo chmod +x /usr/local/bin/mongodb-s3-backup.sh
```

---

# 12. Test backup manually

Run:

```bash
sudo /usr/local/bin/mongodb-s3-backup.sh
```

Check local backup:

```bash
ls -lh /var/backups/mongodb/
```

Check log:

```bash
sudo cat /var/log/mongodb-s3-backup.log
```

Check S3:

```bash
aws s3 ls s3://YOUR_BUCKET_NAME/mongodb-backups/
```

A successful backup should produce a file similar to:

```text
studentdb_2026-09-02_02-00-00.archive.gz
```

---

# 13. Cron automation

Edit root cron:

```bash
sudo crontab -e
```

Daily at 2:00 AM:

```cron
0 2 * * * /usr/local/bin/mongodb-s3-backup.sh
```

Check:

```bash
sudo crontab -l
```

Check Cron:

```bash
sudo systemctl status cron --no-pager
```

For temporary testing, use:

```cron
*/5 * * * * /usr/local/bin/mongodb-s3-backup.sh
```

After confirming it works, change it back to:

```cron
0 2 * * * /usr/local/bin/mongodb-s3-backup.sh
```

---

# 14. Restore test

List backups:

```bash
aws s3 ls s3://YOUR_BUCKET_NAME/mongodb-backups/
```

Download a backup:

```bash
aws s3 cp   s3://YOUR_BUCKET_NAME/mongodb-backups/BACKUP_FILE.archive.gz   /tmp/BACKUP_FILE.archive.gz
```

Restore into a separate test database:

```bash
mongorestore   --gzip   --archive=/tmp/BACKUP_FILE.archive.gz   --nsFrom="studentdb.*"   --nsTo="studentdb_restore_test.*"
```

Verify:

```bash
mongosh
```

Then:

```javascript
show dbs
use studentdb_restore_test
show collections
db.students.find()
```

Exit:

```javascript
exit
```

Never test restoration by overwriting production data first.

---

# 15. Security configuration

EC2 Security Group should normally expose only required ports.

Typical setup:

```text
22    SSH       Your IP only
80    HTTP      0.0.0.0/0
443   HTTPS     0.0.0.0/0
5000  Node.js   Do NOT expose publicly
27017 MongoDB   Do NOT expose publicly
```

Check listening ports:

```bash
sudo ss -lntp
```

Check Nginx:

```bash
sudo systemctl status nginx
```

Check backend:

```bash
sudo systemctl status myapp-backend
```

Check MongoDB:

```bash
sudo systemctl status mongod
```

---

# 16. Useful troubleshooting commands

### Nginx

```bash
sudo nginx -t
sudo systemctl status nginx
sudo journalctl -u nginx -n 100 --no-pager
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Node.js backend

```bash
sudo systemctl status myapp-backend
sudo journalctl -u myapp-backend -n 100 --no-pager
sudo journalctl -u myapp-backend -f
curl http://127.0.0.1:5000/api/health
```

### MongoDB

```bash
sudo systemctl status mongod
mongosh --eval 'db.runCommand({ ping: 1 })'
```

### S3

```bash
aws sts get-caller-identity
aws s3 ls s3://YOUR_BUCKET_NAME/
aws s3 ls s3://YOUR_BUCKET_NAME/mongodb-backups/
```

### Ports

```bash
sudo ss -lntp
```

### Processes

```bash
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
```

---

# 17. GitHub setup

This repo already ships with a `.gitignore` and a `backend/.env.example`, so secrets are excluded by default.

Important: Do not upload:

- AWS access keys
- `.env`
- passwords
- private keys
- production secrets
- database credentials

Initialize Git and make your first commit:

```bash
cd myapp-devops-end-to-end

git init
git add .
git status
git commit -m "Initial full-stack DevOps deployment"
```

Create an empty repository on GitHub (no README/.gitignore/license selected there, since you already have them), then set the remote and push:

```bash
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

Replace the username and repository name with your own GitHub repository.

Before your first commit, double-check nothing sensitive is staged:

```bash
git status
git diff --cached
```

---

# 18. Final validation checklist

```bash
# Frontend
ls -la /var/www/myapp/frontend/dist/

# Backend
sudo systemctl is-active myapp-backend

# MongoDB
sudo systemctl is-active mongod

# Nginx
sudo systemctl is-active nginx

# Backend health
curl http://127.0.0.1:5000/api/health

# Nginx API
curl http://127.0.0.1/api/health

# S3 identity
aws sts get-caller-identity

# Backup
sudo /usr/local/bin/mongodb-s3-backup.sh

# S3 backup
aws s3 ls s3://YOUR_BUCKET_NAME/mongodb-backups/

# Cron
sudo crontab -l
```

## Expected production flow

```text
User
  |
  v
EC2 Public IP / Domain
  |
  v
Nginx :80/:443
  |
  +----------------------+
  |                      |
  v                      v
React Frontend       /api/*
                         |
                         v
                    Node.js :5000
                         |
                    +----+----+
                    |         |
                    v         v
                 MongoDB      S3
                 :27017    App Data
                    |
                    v
                mongodump
                    |
                    v
               gzip archive
                    |
                    v
                 S3 Backup
                    ^
                    |
                   Cron
```

## Project outcome

This project demonstrates a practical DevOps deployment with:

- Linux server administration
- Nginx web server and reverse proxy
- React production build
- Node.js backend deployment
- MongoDB database integration
- systemd service management
- AWS IAM and S3 integration
- automated database backup
- gzip compression
- Cron scheduling
- S3 backup verification
- database restore testing
- basic production security
