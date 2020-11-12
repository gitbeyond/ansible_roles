# -*- coding: utf-8 -*-
import time

def binary_search(arr, item):
    if not arr:
        return False
    
    #idx = 0
    arr_len = len(arr)
    loop_count=1

    while True:
        if arr_len > len(arr)*2:
            #arr_len = len(arr)*2-1
            return False

        if arr_len <= 0:
            return False
            
        print('arr_len: %d' % arr_len)

        # 使用总长度除以循环次数得到剩余的长度

        rest_len = arr_len / (loop_count+1)

        if arr_len >= len(arr) * 2:
            mid = arr_len / 2 - 1
        else:
            mid = arr_len / 2

        if item == arr[mid]:
            return item

        # 当 item < arr[mid] 值，那么mid的值应该变小
        # 按照 mid 为 5 来计算，下一次 5/2，那么 mid 应该是 2
        # 此时是第一次循环，
        # arr_len = 10
        # loop_count = 1
        # rest_len = 10
        # mid = 5
        # 4 < arr[5]=6 

        elif item < arr[mid]:
            #arr_len = arr_len / 2 - arr_len
            print("item < %d, mid: %d " %(arr[mid], mid))
            # 假设这里把 arr_len 长度自减了一半 
            arr_len = arr_len / 2 


        # 当 item > arr[mid] 值，那么 mid 值应该变大
        # 按照 mid 为 2 来计算，4 > arr[2]=3, mid 值应该成为 5 到 2 之间的数
        # 此时是第一次循环
        # arr_len = 10
        # loop_count = 1
        # rest_len = 10
        # mid = 5
        # 8 > arr[5]=6
        elif item > arr[mid]:
            print("item > %d, mid: %d" % (arr[mid], mid))
            #arr_len = arr_len + rest_len 
            arr_len = arr_len + rest_len
            # 当 arr_len 是  15 的时候, 其再加上自己的 15/2的值，就成了 22 了，这是不对的，
            # 他应该加的是剩余的列表长度一半, 

        # 第三次循环
        # arr_len = 7
        # loop_count = 3
        # rest_len = 2
        # mid = 3
        loop_count +=1 
          
            

a = [1,2,3,4,5,6,7,8,9,10]
b = [ 35, 46, 57, 68, 79, 90, 101, 112, 120]

for i in a:
    print(binary_search(a, i))
    time.sleep(5)
#print(binary_search(b, 79))

