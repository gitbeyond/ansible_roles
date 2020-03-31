egrep "^lp:|^sync:|^halt:|^news:|^uucp:|^operator:|^games:|^gopher:|^smmsp:|^nfsnobody:|^nobody:|^adm:|^shutdown:" /etc/shadow|awk -F: '($2!~/\*(.*)/) {print $1":"$2}' 
egrep "^lp:|^sync:|^halt:|^news:|^uucp:|^operator:|^games:|^gopher:|^smmsp:|^nfsnobody:|^nobody:|^adm:|^shutdown:" /etc/passwd|awk -F: '($7!~/bin\/false/) {print $1":"$7}' 
echo "num_of_LK="`egrep "^lp:|^sync:|^halt:|^news:|^uucp:|^operator:|^games:|^gopher:|^smmsp:|^nfsnobody:|^nobody:|^adm:|^shutdown:" /etc/shadow|awk -F: '($2!~/\*(.*)/) {print $1":"$2}'|wc -l` 
echo "num_of_shell="`egrep "^lp:|^sync:|^halt:|^news:|^uucp:|^operator:|^games:|^gopher:|^smmsp:|^nfsnobody:|^nobody:|^adm:|^shutdown:" /etc/passwd|awk -F: '($7!~/bin\/false/) {print $1":"$7}'|wc -l`
