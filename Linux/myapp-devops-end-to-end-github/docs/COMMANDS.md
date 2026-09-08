# Quick Commands

## Services

```bash
sudo systemctl status nginx
sudo systemctl status myapp-backend
sudo systemctl status mongod
```

## Restart

```bash
sudo systemctl restart nginx
sudo systemctl restart myapp-backend
sudo systemctl restart mongod
```

## Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## Backend

```bash
curl http://127.0.0.1:5000/api/health
sudo journalctl -u myapp-backend -f
```

## MongoDB

```bash
mongosh --eval 'db.runCommand({ ping: 1 })'
```

## S3

```bash
aws sts get-caller-identity
aws s3 ls s3://YOUR_BUCKET_NAME/mongodb-backups/
```

## Backup

```bash
sudo /usr/local/bin/mongodb-s3-backup.sh
ls -lh /var/backups/mongodb/
sudo cat /var/log/mongodb-s3-backup.log
```

## Cron

```bash
sudo crontab -l
sudo systemctl status cron --no-pager
```
