# placement_check
#little script for check placement error

# run ./check_placement.sh if you want to check all compute nodes 
# run ./check_placement.sh cmp001 cmp002 <other compute node names> if you wanna check allocation error on target devices. 
  
  
# the script will generate the list of broken allocations, you can access it in output.log file
# the script will generate te list of command to delete broken allocations. you can access it in delete_list. you can run them use "bash delete_list" command.
