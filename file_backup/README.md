example:

```yaml

# deploy_jenkins_backup.yml
- hosts: jenkins
  remote_user: root
  roles:
    - { role: file_backup, backup_remote_host: '172.16.1.120'}
```
