#!/bin/bash

# openstack resource provider show --allocation 0ca66b10-43e0-41e6-a30c-39b3719c0246 -f yaml  | grep -E -o "[[:alnum:]]{8}[-]([[:alnum:]]{4}[-]){3}[[:alnum:]]{12}" 

host_list=$(openstack resource provider list)


exec 2>error_list
exec 1>output


for host in $(cat /etc/hosts | grep -E -o "cmp[0-9]{3}")
#for host in cmp001 cmp002
do
#    echo $host
    host_id=$(echo "$host_list" | grep $host | awk '{print $2}')
    server_list=$(openstack server list --all --host $host -c 'ID')
    for allocation in $(openstack resource provider show --allocation $host_id -f yaml | grep -v "uuid"  | grep -E -o "[[:alnum:]]{8}[-]([[:alnum:]]{4}[-]){3}[[:alnum:]]{12}")
    do
        #if ! (echo "$allocation_output" | grep -q $host)
        if ! (echo "$server_list" | grep -q $allocation )
        then
            allocation_output=$(openstack server show $allocation)
            if ! (echo "$allocation_output" | grep -q host) 
            then
                result="instance doesn't exist anymore. remove it manually from DB"
            else 
                result=$(echo "$allocation_output" | grep -w host | awk '{print $4}')
            fi
           echo -e "$host\t$allocation\t$result"
        fi
    done
done

