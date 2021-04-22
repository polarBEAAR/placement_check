#!/bin/bash

. /root/keystonercv3      ### contain openstack credentials
#. ~/delete_placement.sh   ### contain script to delete  allocations. usage: "delete $host_uuid $allocation_uuid"
#. ~/check_placement.sh    ### contain script to check allocations. usage: "check" - will check all accessible hosts; "check <compute node name>" - will check allocations on specified host

### global var

exec 1>output.log
exec 2>error.log
exec 4>delete_list        ### to avoid enduser-error, the script do not delete the rows from DB. Script generate the list of deletion command only and put it in the file called "delete_list"


row="%-8s %-40s %-40s %-30s %-10d %-10d %-10d \n"                                                                ### format string
printf "%-8s %-40s %-40s %-30s %-10s %-10s %-10s \n" "Host" "Host UUID" "Allocation ID" "Result" "RAM" "CPU" "Disk"

### mhost is a var for mysql host adress, mpasswd is a var for mysql password. Both they are required for delete left allocations.

mhost=$(salt-call pillar.get nova:controller:database:host | awk '{print $1}' | grep -v "local")
mpasswd=$(salt-call pillar.get nova:controller:database:password | awk '{print $1}' | grep -v "local")

### delete function

function delete_plc {

rp_id=$(mysql -sN  -unova -h"$mhost" -p"$mpasswd" -D nova_api -e "select id from resource_providers where uuid='$1'")    ### rp_id - 

#echo "mysql -unova -h"$mhost" -p"$mpasswd" -D nova_api -e \"select * from allocations where consumer_id='$2' and resource_provider_id='$rp_id'\" ">&4
echo "mysql -unova -h"$mhost" -p"$mpasswd" -D nova_api -e \"delete from allocations where consumer_id='$2' and resource_provider_id='$rp_id'\" ">&4
}

### generate a list of arguments (hosts)

if  [ -z "$1" ]
then
    list=$(openstack compute service list | grep -o -E "cmp0[0-9]*")     ### if there's no arguments script will be run across all compute nodes
else
    list=("$@")
fi


### main check

for host in ${list[*]}
do
    
    host_id=$(openstack resource provider list | grep $host | awk '{print $2}')
    server_list=$(openstack server list --all --host "$host" -c 'ID' )
    allocation_list=$(openstack resource provider show --allocation "$host_id" -f yaml)

    for allocation in $(echo "$allocation_list" | grep -v "uuid"  | grep -E -o "[[:alnum:]]{8}[-]([[:alnum:]]{4}[-]){3}[[:alnum:]]{12}")    ### took all allocation for the host
    do
        if ! (echo "$server_list" | grep -q "$allocation" )                                                                                 ### took only allocation which are not presented on the host (origin server was migrated )
        then
            allocation_output=$(openstack server show "$allocation")



            if ! (echo "$allocation_output" | grep -q host)                                                                                 ### took only allocation which doesn't exist anymore. ( origin server was deleted )
            then
                result="doesn't exist anymore"
            else
                result=$(echo "$allocation_output" | grep -w host | awk '{print $4}')
            fi
            delete_plc "$host_id" "$allocation"                                                                                             ### deletion commands are generated. you can delete all broken allocations run "bash delete_list"
            printf "$row" "$host" "$host_id" "$allocation" "$result"
        fi
    done
done
