export PATH={{containerd_base_dir}}/{{containerd_relative_bin_path}}:{%- if "usr" in containerd_relative_bin_path -%}{{containerd_base_dir}}/{{containerd_relative_bin_path |replace("/bin", "/sbin") }}:{%-endif-%}${PATH}