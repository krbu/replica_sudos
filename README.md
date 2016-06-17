# replica_sudos
script to replicate sudoer foles on several servers from an intermediate server with public key in a remote machine's authorized_keys
# usage
Usage: ./replica_sudos.sh [OPTIONS...]

Change Types:

-u USER         User with admin privileges.
-S SERVERS      file with the servers to apply.
-s SUDOS        Comma separated sudo groups list. If this parameter is not specified all files located on /etc/sudoers.d will be processed

Examples:


 ./replica_sudos.sh -u user -S servers_list.txt 


 ./replica_sudos.sh -u user -S servers_list.txt -s monteam,dbateam,unixteam
