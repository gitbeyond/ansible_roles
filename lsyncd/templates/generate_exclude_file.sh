str1="workspace/**target**.jar jobs/**target**.jar workspace/**.repository workspace/**.tgz jobs/**.tgz workspace/**.tar.gz workspace/**.zip jobs/**.tar.gz jobs/**.zip workspace/**node_modules jobs/**node_modules workspace/**png jobs/**png workspace/**class jobs/**class jobs/**modules**jar jobs/**git workspace/**git workspace/**gif workspace/**src** workspace/**target** workspace/**.repository** workspace/**jpg jobs/**jpg workspace/**.mvn** jobs/**.mvn** workspace/**.svn** jobs/**.svn** workspace/i**log jobs/**log jobs/**/builds/.** jobs/**modules**builds**archive jobs**modules**builds/*/**.* jobs/*/builds/* workspace jobs/*/modules**builds/*"

str1="jobs/**target**.jar jobs/**.tgz jobs/**.tar.gz jobs/**.zip jobs/**node_modules jobs/**png jobs/**class jobs/**modules**jar jobs/**git jobs/**.mvn** jobs/**.svn** jobs/**log jobs/**/builds/.** jobs/**modules**builds**archive jobs**modules**builds/*/**.* jobs/*/builds/* workspace jobs/*/modules**builds/*"

echo -n '{'
for i in ${str1};do
    #echo -n "\"*${i}\", "
    echo -n "\"${i}\", "
done
echo -n '}'
