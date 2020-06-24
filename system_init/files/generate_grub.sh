#!/bin/bash

grub_cfg=/boot/grub2/grub.cfg
grub2_mkconfig(){

    if grep "ipv6.disable=1" ${grub_cfg};then
        return 0
    else
        grub2-mkconfig -o ${grub_cfg}
        if [ $? == 0 ];then
            return 11
        else
            return 12
        fi
    fi
}

grub2_mkconfig
