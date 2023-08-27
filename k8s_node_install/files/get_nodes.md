
# kubectl 命令
* 实际的观察发现，其也是从服务端获取了全量的数据，然后根据规则在本地处理后，再输出的
* 并不是说服务器返回的就是筛选后的字段信息
```bash
k get no -o custom-columns='NODE:metadata.name,INTERNAL_IP:status.addresses[?(@.type == "InternalIP")].address'

k get no -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[?(@.type == "InternalIP")].address}{"\n"}{end}'
```

# ansible

```
{{lookup('kubernetes.core.k8s', kind='Node' ) | map(attribute='status.addresses') }}
{{lookup('kubernetes.core.k8s', kind='Node' ) | map('community.general.json_query','status.addresses')   }}
{{lookup('kubernetes.core.k8s', kind='Node' ) | community.general.json_query('[].status.addresses')   }}
```

```yaml
- hosts: localhost
  vars:
    query_str: "[].status.addresses[?type=='InternalIP' || type=='Hostname']"
  tasks:
  - name: debug
    ansible.builtin.debug:
      msg: "{{lookup('kubernetes.core.k8s', kind='Node' ) | community.general.json_query(query_str)}}"

```

```yaml
- hosts: localhost
  vars:
    #query_str: "[].status.addresses[?type=='InternalIP' || type=='Hostname']"
    #query_str: "[].status.addresses[?type=='InternalIP'].{ip: address}"
    # the nest query is incorrect
    #query_str: "[?status.addresses[?type=='InternalIP'].address=='172.25.49.10'].metadata.name"
    # this is basiclly correct
    #query_str: "[].{name: metadata.name, ip: status.addresses[?type=='InternalIP']}"
    # this is best
    query_str: "[].{value: metadata.name, key: status.addresses[?type=='InternalIP'] | [0].address}"
  tasks:
  - name: set fact1
    ansible.builtin.set_fact:
      k8s_nodes: "{{lookup('kubernetes.core.k8s', kind='Node' ) }}"
  - name: set fact2
    # the method is raw and not nice
    ansible.builtin.set_fact:
      k8s_nodes_ip_map: |
        [
            {%for node in k8s_nodes%}
                {% for addr in node.status.addresses %}
                     {% if addr.type == "InternalIP"%}
                         {% set ip=addr.address %}
                         {{ {"node": node.metadata.name, "ip": ip} }},
                     {% endif%}
                {% endfor %}
            {%endfor%}
        ]
  - name: debug k8s_nodes
    ansible.builtin.debug:
      msg: "{{k8s_nodes_ip_map}}"
  - name: debug
    ansible.builtin.debug:
      msg: "{{lookup('kubernetes.core.k8s', kind='Node' ) | community.general.json_query(query_str) | items2dict}}"


```
* https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html 
* https://jmespath.org/examples.html : 

