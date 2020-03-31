netrc_num=$(find / -maxdepth 3 -name .netrc 2>/dev/null| wc -l )
rhosts_num=$(find / -maxdepth 3 -name .rhosts 2>/dev/null| wc -l )
hosts_equiv_num=$(find / -maxdepth 3 -name hosts.equiv 2>/dev/null| wc -l)
#echo "netrc_num="`find / -maxdepth 3 -name .netrc 2>/dev/null|wc -l` 
#echo "rhosts_num="`find / -maxdepth 3 -name .rhosts 2>/dev/null|wc -l` 
#echo "hosts.equiv_num="`find / -maxdepth 3 -name hosts.equiv 2>/dev/null|wc -l` 

if [ ${netrc_num} -ne 0 ] || [ ${rhosts_num} -ne 0 ] || [ ${hosts_equiv_num} -ne 0 ];then
    exit 1
fi
