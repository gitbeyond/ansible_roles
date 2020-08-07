modprobe vxlan  
lsmod | grep vxlan  
  
ip netns add zou  
ip netns add huiying  
ip netns show  
  
ip link add zouveth0 type veth peer name zouveth1   
ip link add hyveth0 type veth peer name hyveth1  
  
ip link set zouveth1 netns zou  
ip link set hyveth1 netns huiying  
  
ip netns exec zou ip a add dev zouveth1 10.1.0.6/24  
ip netns exec huiying ip a add dev hyveth1 10.1.0.6/24  
  
brctl addbr br-zou  
brctl addbr br-hy  
  
brctl addif br-zou zouveth0  
brctl addif br-hy hyveth0  
brctl show  
  
ip link add vxlan-10 type vxlan id 10 remote 10.111.32.209  dstport 8900 dev br0 
ip link add vxlan-20 type vxlan id 20 remote 10.111.32.209 dstport 8900 dev br0  
  
ip -d link show vxlan-10  
ip -d link show vxlan-20  
  
brctl addif br-zou vxlan-10  
brctl addif br-hy vxlan-20  
brctl show  
  
  
ip link set dev zouveth0 up  
ip link set dev hyveth0 up  
  
ip netns exec zou ip link set dev zouveth1 up  
ip netns exec huiying ip link set dev hyveth1 up  
  
ip netns exec zou ip link set dev lo up  
ip netns exec huiying ip link set dev lo up  
  
ip link set dev br-zou up  
ip link set dev br-hy up  
  
ip link set dev vxlan-10 up  
ip link set dev vxlan-20 up
