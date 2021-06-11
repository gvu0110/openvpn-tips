# upgrade

- [upgrade](#upgrade)
  - [OS upgrade](#os-upgrade)
  - [OpenVPN Access Server update](#openvpn-access-server-update)

## OS upgrade
**1. Backup and Rollback**
- Take the EBS snapshot of the instance
- Create an image from the snapshot
- Create a volume in the same AZ with the instance
- In case of upgrade failures:
  + Detach the old the volume and attach the new volume to `/dev/sda1`

  or

  + Create new instance from the new image
Using the AWS console to backup snapshots and restore in case of failures

References:
[Backing up and restoring snapshots on Amazon EC2 machines](https://www.techrepublic.com/blog/the-enterprise-cloud/backing-up-and-restoring-snapshots-on-amazon-ec2-machines/)

**2. Upgrade**

Check the current OS version
```bash
cat /etc/issue
lsb_release -a
uname -a
```
Keep current version up-to-date
```bash
sudo apt update && sudo apt upgrade
```
Change software dependencies with new versions of packages
```bash
sudo apt dist-upgrade
```
Remove dependencies from uninstalled applications
```bash
sudo apt-get autoremove
```
Install the Ubuntu Update Manager
```bash
sudo apt install update-manager-core
```
Finally, start upgrading the OS system
```bash
sudo do-release-upgrade
```
References:
[How to upgrade from Ubuntu Linux 16.04 to 18.04](https://www.zdnet.com/article/how-to-upgrade-from-ubuntu-linux-16-04-to-18-04/)

## OpenVPN Access Server update
Helpful link: [Updating OpenVPN Access Server](https://openvpn.net/vpn-server-resources/keeping-openvpn-access-server-updated/)

**1. Backup configuration**

Use the following commands to backup OpenVPN Access Server configuration with root privileges.
```bash
which apt > /dev/null 2>&1 && apt -y install sqlite3
cd /usr/local/openvpn_as/etc/db
[ -e config.db ]&&sqlite3 config.db .dump>../../config.db.bak
[ -e certs.db ]&&sqlite3 certs.db .dump>../../certs.db.bak
[ -e userprop.db ]&&sqlite3 userprop.db .dump>../../userprop.db.bak
[ -e log.db ]&&sqlite3 log.db .dump>../../log.db.bak
[ -e config_local.db ]&&sqlite3 config_local.db .dump>../../config_local.db.bak
[ -e cluster.db ]&&sqlite3 cluster.db .dump>../../cluster.db.bak
[ -e clusterdb.db ]&&sqlite3 clusterdb.db .dump>../../clusterdb.db.bak
[ -e notification.db ]&&sqlite3 notification.db .dump>../../notification.db.bak
cp ../as.conf ../../as.conf.bak
```
The resulting backup files ending in `.bak` can be found in the `/usr/local/openvpn_as/`

References:
[Backing up the OpenVPN Access Server configuration](https://openvpn.net/vpn-server-resources/configuration-database-management-and-backups/#backing-up-the-openvpn-access-server-configuration)

**2. Upgrade**

Please refer to the OpenVPN Access Server software packages [download page](https://openvpn.net/vpn-software-packages/) and select proper Ubuntu version to get the install command.

The following example commands is for Ubuntu 18.04.
```bash
sudo apt update && apt -y install ca-certificates wget net-tools gnupg
sudo wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add -
echo "deb http://as-repository.openvpn.net/as/debian bionic main">/etc/apt/sources.list.d/openvpn-as-repo.list
sudo apt update && apt -y install openvpn-as
```
After these steps, the Access Server is upgraded

References:
[Installations and upgrades using the official OpenVPN Software Repository](https://openvpn.net/vpn-server-resources/keeping-openvpn-access-server-updated/#software-repository)

**3. (Optional) Rollback**

Use the following commands to restore OpenVPN Access Server configuration from backup files with root privileges
```bash
service openvpnas stop
which apt > /dev/null 2>&1 && sudo apt -y install sqlite3
cd /usr/local/openvpn_as/etc/db
[ -e ../../config.db.bak ]&&rm config.db;sqlite3<../../config.db.bak config.db
[ -e ../../certs.db.bak ]&&rm certs.db;sqlite3 <../../certs.db.bak certs.db
[ -e ../../userprop.db.bak ]&&rm userprop.db;sqlite3 <../../userprop.db.bak userprop.db
[ -e ../../log.db.bak ]&&rm log.db;sqlite3 <../../log.db.bak log.db
[ -e ../../config_local.db.bak ]&&rm config_local.db;sqlite3 <../../config_local.db.bak config_local.db
[ -e ../../cluster.db.bak ]&&rm cluster.db;sqlite3 <../../cluster.db.bak cluster.db
[ -e ../../clusterdb.db.bak ]&&rm clusterdb.db;sqlite3 <../../clusterdb.db.bak clusterdb.db
[ -e ../../notification.db.bak ]&&rm notification.db;sqlite3 <../../notification.db.bak notification.db
[ -e ../../as.conf.bak ]&&cp ../../as.conf.bak ../as.conf
service openvpnas start
```
References:
[Recovering a server with SQlite3 dump backup files](https://openvpn.net/vpn-server-resources/configuration-database-management-and-backups/#recovering-a-server-with-sqlite3-dump-backup-files)
