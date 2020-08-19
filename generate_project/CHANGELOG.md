# 2020/06/18 set local_action tasks become to no

当使用普通用户在本地进行操作时，生成的目录和文件都是 become 的用户，这不太合理，因此改为 become: no

# 2020/08/05 fix generate vars file bug

```yaml
projects:
  - project_name: app1
    project_run_port: 8080
  - project_name: app2
    project_run_port: 8081
```
当有如上这样的结构时，生成的 vars 文件，只会生成一个，是 vars/app1.yml，但是其中的内容先是 app1 的内容，
再变在 app2 的内容，等于在第二次循环的时候，vars file 的名字没有被正常替换。


后经测试，添加了 `project_prog_name: '{{project_item.project_prog_name | default(project_item.project_name, true)}}'`，
这一行后恢复正常, `project_vars_file: '{{project_prog_name | default(project_name, true)}}.yml'` 
当中会去取 project_prog_name 和 project_name 变量，你不传给他，他优先使用的 project_prog_name 是 `include_vars: vars/app1.yml`
中的变量, 在`gen_vars_file.yml` 中 `include_vars: project_empty_vars.yml` 验证了这个想法，`project_empty_vars.yml` 中只是将
`project_prog_name` 置为 none, 根据 `defaults/main.yml`中`project_prog_name` 的设置，为 none 时，使用 `project_name`的值，而
`project_name: '{{project_item.project_name}}'` 所以没有问题,

目前来说，不知道引入 `project_empty_vars.yml` 是否会有问题，还是建议应该把变量写全。

后期可以考虑在 role 内自循环，而不是对 role 进行循环。
```yaml
tasks:
  - name: debug projects
    debug:
      msg: '{{lookup("file", "vars/main.yml") | from_yaml | json_query("projects")}}'
  - name: generate project
    include_role:
      name: generate_project
      #tasks_from: gen_vars_file.yml
      #tasks_from: gen_jenkinsfile.yml
      #tasks_from: gen_jenkins_job.yml
      #tasks_from: add_job_to_view.yml
    vars:
      project_vars: '{{project_item}}'
      project_prog_name: '{{project_item.project_prog_name | default(project_item.project_name, true)}}'
      project_name: '{{project_item.project_name}}'
    loop: '{{lookup("file", "vars/main.yml") | from_yaml | json_query("projects")}}'
    loop_control:
      loop_var: project_item
```
