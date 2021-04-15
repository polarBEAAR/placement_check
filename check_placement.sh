#!/bin/bash

exec 2>error_list
#exec 1>output

rm completed

row="%-8s %-40s %-30s %-10d %-10d %-10d \n"
printf "%-8s %-40s %-30s %-10s %-10s %-10s \n" "Host" "Allocation ID" "Result" "RAM" "CPU" "Disk"

memory=0
cpu=0
disk=0


if !  [ -n "$1" ]
then
    list=$(cat /etc/hosts | grep -o "\<cmp0[0-9]*$")
else
    list=$@
fi


host_list=$(openstack resource provider list)
for host in $(echo "$list")
do
    host_id=$(echo "$host_list" | grep $host | awk '{print $2}')
    server_list=$(openstack server list --all --host $host -c 'ID')
    allocation_list=$(openstack resource provider show --allocation $host_id -f yaml)

    for allocation in $(echo "$allocation_list" | grep -v "uuid"  | grep -E -o "[[:alnum:]]{8}[-]([[:alnum:]]{4}[-]){3}[[:alnum:]]{12}")
    do
        if ! (echo "$server_list" | grep -q $allocation )
        then
            allocation_output=$(openstack server show $allocation)

            current_ram=$(echo "$allocation_list" | grep -A 4 $allocation | grep -i memory | awk '{print $2}')
            let " memory = memory + current_ram "

            current_cpu=$(echo "$allocation_list" | grep -A 4 $allocation | grep -i cpu | awk '{print $2}')
            let " cpu = cpu + current_cpu "

            current_disk=$(echo "$allocation_list" | grep -A 4 $allocation | grep -i disk | awk '{print $2}')
            let "disk = disk + current_disk"
            
            if ! (echo "$allocation_output" | grep -q host) 
            then
                result="doesn't exist anymore"
            else 
                result=$(echo "$allocation_output" | grep -w host | awk '{print $4}')
            fi
            printf "$row" $host $allocation "$result" $current_ram $current_cpu $current_disk
        fi
    done
done
printf "%-80s %-10d %-10d %-10d \n" "Total" $memory $cpu $disk

touch completed
