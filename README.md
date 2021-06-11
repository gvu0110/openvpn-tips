# openvpn-tips

- [openvpn-tips](#openvpn-tips)
  - [Logging](#logging)
  - [DNS settings with Cisco Umbrella](#dns-settings-with-cisco-umbrella)
  - [2FA Google Authenticator](#2fa-google-authenticator)
  - [LDAP Authentication with JumpCloud](#ldap-authentication-with-jumpcloud)
  - [Locked out](#locked-out)
  - [Security](#security)

## Logging
- Install datadog-agent and enable log collection
```sh
sudo vim /etc/datadog-agent/datadog.yaml

## @param hostname - string - optional - default: auto-detected
## Force the hostname name.
#
hostname: openvpn

## @param logs_enabled - boolean - optional - default: false
## Enable Datadog Agent log collection by setting logs_enabled to true.
#
logs_enabled: true
logs_config:
  use_http: true
  use_compression: true
  compression_level: 6
```
- Configure the datadog-agent
```sh
sudo mkdir /etc/datadog-agent/conf.d/openvpnas.d
sudo vim /etc/datadog-agent/conf.d/openvpnas.d/conf.yaml

logs:
  - type: file
    path: /var/log/openvpnas.log
    service: openvpn
    source: custom

vim /etc/datadog-agent/conf.d/auth.d/conf.yaml

logs:
  - type: file
    path: /var/log/auth.log
    service: auth
    source: auth

vim /etc/datadog-agent/conf.d/syslog.d/conf.yaml

logs:
  - type: file
    path: /var/log/syslog
    service: syslog
    source: syslog
```

## DNS settings with Cisco Umbrella
Pushing Cisco Umbrella DNS servers to clients:
- Primary DNS Server: 208.67.220.220
- Secondary DNS Server: 208.67.222.222

## 2FA Google Authenticator
- Enable Google Authenticator globally for all users and groups:
```sh
sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.google_auth.enable" --value "true" ConfigPut

sudo /usr/local/openvpn_as/scripts/sacli start
```
- Enable Google Authenticator for a specific group:
```sh
sudo /usr/local/openvpn_as/scripts/sacli --user <GROUP_NAME> --key "prop_google_auth" --value "true" UserPropPut
```
- Unlock an already scanned and locked secret for a user, so the user can obtain/scan it again:
```sh
sudo /usr/local/openvpn_as/scripts/sacli --user <USERNAME> --lock 0 GoogleAuthLock
```
- Generate a new secret key and unlock it so the user can enroll anew:
```sh
sudo /usr/local/openvpn_as/scripts/sacli --user <USERNAME> --lock 0 GoogleAuthRegen
```

## LDAP Authentication with JumpCloud
- Get CA chain from JumpCloud
```sh
sudo echo -n | openssl s_client -connect ldap.jumpcloud.com:636 -showcerts | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /etc/ssl/certs/jumpcloud.chain.pem
```
- Configure LDAP for users are members of **OpenVPN LDAP Users** JumpCloud group
```sh
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.name" --value "JumpCloud Secure LDAP" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.server.0.host" --value "ldap.jumpcloud.com" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.use_ssl" --value "always" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.ssl_verify" --value "demand" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.ssl_ca_cert" --value "/etc/ssl/certs/jumpcloud.chain.pem" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.min_ssl" --value "tls1_2" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.sasl_external" --value "false" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.case_sensitive" --value "false" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.bind_dn" --value "uid=<INIT_USERNAME>,ou=Users,o=<ORGANIZATION_ID>,dc=jumpcloud,dc=com" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.bind_pw" --value <INIT_PASSWORD> ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.users_base_dn" --value "OU=Users,o=<ORGANIZATION_ID>,DC=jumpcloud,DC=com" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.uname_attr" --value "uid" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.ldap.0.add_req" --value "memberOf=cn=OpenVPN LDAP Users,ou=Users,o=<ORGANIZATION_ID>,dc=jumpcloud,dc=com" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "auth.module.type" --value "ldap" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli start
```
**Troubleshooting**
- Test LDAP connection
```sh
openssl s_client -connect ldap.jumpcloud.com:636

Verify return code: 0 (ok)
```
- Test LDAP authentication
```sh
sudo ./authcli -u <USERNAME> -p <PASSWORD>
```
- Enable debug and trace level (to disable, set `--value` to 0). Logs will be stored at `/var/log/openvpnas.log`
```sh
sudo ./sacli --key "auth.ldap.0.debug_level" --value 1 ConfigPut
sudo ./sacli --key "auth.ldap.0.openldap_trace_level" --value 1 ConfigPut
sudo ./sacli start
```
**LDAP Failure**
- In case of LDAP failure, change back to local authentication mode
```
sudo ./sacli --key "auth.module.type" --value "local" ConfigPut
sudo ./sacli start
```
- Add a new user and set the user as admin the local authentication mode
```
sudo ./sacli --user <USERNAME> --key "type" --value "user_connect" UserPropPut
sudo ./sacli --user <USERNAME> --new_pass <PASSWORD> SetLocalPassword
sudo ./sacli --user <USERNAME> --key "prop_superuser" --value "true" UserPropPut
sudo ./sacli start
```

## Locked out
- There is no way to unlock a specific user from 15-minute lock out. The only way is changing the value of lock out policy to 1 second and change back to 15 minutes.
```sh
sudo /usr/local/openvpn_as/scripts/confdba -mk vpn.server.lockout_policy.reset_time -v 1
sudo /usr/local/openvpn_as/scripts/sacli start
sleep 2
sudo /usr/local/openvpn_as/scripts/confdba -mk vpn.server.lockout_policy.reset_time -v 900
sudo /usr/local/openvpn_as/scripts/sacli start
```

## Security
The default user `openvpn` is locked from accessing the Admin UI by the command `sudo passwd -l openvpn`. In order to start using this account again in the future, unlock it and set a new password:
```bash
sudo passwd -u openvpn
sudo passwd openvpn
```
There is no FORCE user to change password on next login at the time of writing
