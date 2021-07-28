# editor: haifengsss@163.com
# date: 2021/07/22
# 作用：从tcpdump的文本数据中找到 tsval 异常的数据包
# 这个是直接使用时间戳的方式，不需要转变时间
# client ip is also different.
BEGIN{
    SUBSEP=":";
}
# a 是记录 ip:port 其 出现的次数, 如 a["103.219.187.61.6952"] = 30
# b 是记录 ip:port 的tsval值, 如 a["103.219.187.61.6952:1"] = 3209094433
# c 是记录 ip:port 的时间信息，如 a["103.219.187.61.6952:1"] = 1626851770
#/^\ *103.85.175.162/{
# 这里的ip是测试时client的公网IP
/^\ *103.219.187.61/{
    #if($1~"103.85.175.162"){
        a[$1]++; 
        #if($1=="103.219.187.61.6952"){
        #    print $0, a[$1]
        #}
        # 获取 tsval 的值
        for(i=1;i<=NF;i++){
            j=i+1;
            if($i ~ "TS" && $j == "val" ){
                k = i + 2;
                ts_val=$k;
                # 至所以要在此判断中操作，是因为有些行，是没有tsval值的，在外面操作会操作到错误的数据
                # 记录tsval的值
                b[$1, a[$1]]=ts_val;
                # 把上一行中的时间信息，切分，取出最前的时间戳
                split(pre_line, pre_line_arr, ".")
                # 记录时间戳信息
                c[$1, a[$1]]= pre_line_arr[1]
                break;
            }
        }
        # 记录tsval的值
        #b[$1, a[$1]]=ts_val;
        # 把上一行中的时间信息，切分，取出最前的时间戳
        #split(pre_line, pre_line_arr, ".")
        # 记录时间戳信息
        #c[$1, a[$1]]= pre_line_arr[1]
        #print "pre_line", pre_line
    #}
}
{
    pre_line=$0;
}
END{
    # a 中存储的是 ip:port 的次数
    for(l in a){
        #print "a[l]", l, " ", a[l];
        dst = l;
        # 获取此 ip:port 的次数, 这个次数是 b 和 c 数组的长度
        dst_count = a[l];
        # b 是保存同一个端口的 时间戳的数组
        for (z=1; z<=dst_count; z++){
            x=z+1;
            dst_num = l":"z
            # x代表下一个索引值，就是当前值后面的值
            dst_num_1 = l":"x
            if (b[dst_num]!=""){
               #     if (l == "103.219.187.61.6952"){
               #         print dst_num, dst_count, a[l], b[dst_num], c[dst_num]
               #     }
                #print  dst_num, b[dst_num]
                if (b[dst_num_1] != ""){
                    #print dst_num_1, b[dst_num_1], c[dst_num_1]
                    # 如果后面的值小于当前值
                    if (b[dst_num_1] < b[dst_num]){
                        diff_second = c[dst_num_1] - c[dst_num]
                        # 如果两者发包的时间相差超过120秒的话，就不输出
                        if (diff_second < 130){
                            print dst_num, b[dst_num], c[dst_num]
                            print dst_num_1, b[dst_num_1], c[dst_num_1]
                            hehe = "lel"
                        }
                    }
                }
            }else{
                break
            }
        }
    }
}
