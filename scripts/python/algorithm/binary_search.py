# -*- coding: utf-8 -*-

def binary_cur(arr, item):
    if not arr:
        return False

    mid = len(arr) / 2
    if item == arr[mid]:
        return item
    # 如果 item > arr[mid],那么要往右侧找
    # 以 item 为 7 来举例
    # 7 > arr[5]
    # arr[5:] = [ 6, 7, 8, 9, 10]
    
    elif item > arr[mid]:
        print("item > %d, %d" %(arr[mid], mid))
        #return binary_cur(arr[mid+1:], item)
        #return binary_cur(arr[mid+1:], item)
        return binary_cur(arr[mid:], item)
    else:
        # 7 < arr[2] = 8
        # arr[:2] = [6, 7]
        print("item < %d, %d" %(arr[mid], mid))
        return binary_cur(arr[:mid], item)

def binary_search(arr, item):
    if not arr:
        return False
    
    #idx = 0
    start = 0
    end = len(arr)-1

    # 开始和结束位置没有问题就一直循环
    while start <= end:
            
        mid = (start + end) / 2

        if item == arr[mid]:
            return item

        # 如果数组元素比 item 大，那么说明要往左侧找
        # 以 7 举例子
        # mid = 4
        # arr[4] < 5
        # start = mid +1 = 5
        # second loop
        # mid = (5 + 9) / 2 = 7
        # arr[7]=8 > 7
        # end = 7 - 1 = 6
        # third loop
        # arr[6] == 7
        
        elif arr[mid] > item:
            #arr_len = arr_len / 2 - arr_len
            print("item > %d, mid: %d" %(arr[mid], mid))
            # 假设这里把 arr_len 长度自减了一半 
            end = mid - 1
        else:
            print("item < %d, mid: %d " %(arr[mid], mid))
            start = mid + 1

    return False


            

a = [1,2,3,4,5,6,7,8,9,10,11]
b = [ 35, 46, 57, 68, 79, 90, 101, 112, 120, 130, 146, 147, 150]

#print(binary_search(a, 8))
for i in a:
    #print(binary_search(b, i))
    #print(binary_cur(b, i))
    print(binary_cur(a, i))

