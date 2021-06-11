# ssl-certificates

## Renewal
Check current SSL certificates
```bash
certbot certificates
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Found the following certs:
  Certificate Name: example.com
    Domains: example.com
    Expiry Date: 2021-04-20 06:27:15+00:00 (VALID: 69 days)
    Certificate Path: /etc/letsencrypt/live/example.com/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/example.com/privkey.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```
The default renewal script `/etc/cron.d/certbot` will not run because there is a systemd timer (a kind of cron job used by systemd) that was configured for the certbot.
``` bash
systemctl list-timers --all
NEXT                         LEFT          LAST                         PASSED       UNIT
Tue 2021-02-09 18:15:47 EST  3h 15min left Tue 2021-02-09 10:02:17 EST  4h 57min ago certbot.timer
Wed 2021-02-10 03:57:21 EST  12h left      Tue 2021-02-09 10:28:54 EST  4h 31min ago apt-daily.timer
Wed 2021-02-10 05:21:18 EST  14h left      Tue 2021-02-09 05:21:18 EST  9h ago       systemd-tmpfiles-clean.timer
Wed 2021-02-10 06:03:25 EST  15h left      Tue 2021-02-09 06:12:10 EST  8h ago       apt-daily-upgrade.timer
n/a                          n/a           n/a                          n/a          ureadahead-stop.timer
```
The certbot timer should be at `/lib/systemd/system/certbot.timer` and it will execute the command specified at `/lib/systemd/system/certbot.service` to automatically renew the SSL certificates before expiry 30 days.

`certbot.timer` will execute the `certbot.service` at 12:00AM and 12:00PM.

The `renew-ssl-certificates.sh` run every day at 12:00AM to detect if the SSL certificates are renewed automatically or not. If the SSL certificates are renewd by the `certbot.service`, the OpenVPN Access Server will be updated.
``` bash
sudo crontab -l

0 0 * * * /root/openvpn/SSL_certificates/renew_ssl_certificates.sh example.com
```
