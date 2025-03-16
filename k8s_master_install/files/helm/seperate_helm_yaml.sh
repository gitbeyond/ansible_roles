#!/bin/bash
# desc: 将 helm template 命令生成的单一文件分割至多个文件当中
#     使用 helm template 时可以使用 --output-dir 来直接生成至多个文件当中
set -euo pipefail

yaml_file=all_templates.yml

awk -v RS="\n---\n|^---\n" -v base_dir=output_dir '{
    if (NF > 0) {
        target = ""
        for (i = 1; i <= NF; i++) {
            if ($i == "Source:") {
                target = $(i + 1)
                break
            }
        }
	# RT 当前的分割符
	# NR 当前记录号
        if (target != "") {
            split(target, layers, "/")
            layers_len = length(layers)
	    target_dir = target
	    sub(layers[layers_len],"",  target_dir)

	    print "target_dir", target_dir
            file_dir = base_dir "/" target_dir
            system("mkdir -p " file_dir)

	    filename = base_dir "/" target
	    print "---" >> filename
            print $0 >> filename
            close(filename)
        }
    }
}' ${yaml_file}

