# desc

将`defaults/main.yml`改为`defaults/main_ref.yml`,否则会有很多`warn`信息。

```yaml
[WARNING]: While constructing a mapping from /home/wanghaifeng/wanghaifeng/ansible_roles/common_app_install/defaults/main.yml, line 1, column 1, found a
duplicate dict key (app_base_dir). Using last defined value only.
[WARNING]: While constructing a mapping from /home/wanghaifeng/wanghaifeng/ansible_roles/common_app_create_dir/defaults/main.yml, line 1, column 1, found a
duplicate dict key (app_base_dir). Using last defined value only.
[WARNING]: While constructing a mapping from /home/wanghaifeng/wanghaifeng/ansible_roles/common_app_packet_install/defaults/main.yml, line 1, column 1, found
a duplicate dict key (app_base_dir). Using last defined value only.
[WARNING]: While constructing a mapping from /home/wanghaifeng/wanghaifeng/ansible_roles/common_app_copy_conf_file/defaults/main.yml, line 1, column 1, found
a duplicate dict key (app_base_dir). Using last defined value only.
```
