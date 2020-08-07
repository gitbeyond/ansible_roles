ip li set dev br-zou down
ip li set dev br-hy down

ip netns del zou
ip netns del huiying

ip link del vxlan-10
ip link del vxlan-20
ip link del zouveth0
ip link del hyveth0

brctl delbr br-zou
brctl delbr br-hy


