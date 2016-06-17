#!/bin/bash
#===============================================================================
#
#          FILE:  replica_sudos.sh
# 
#         USAGE:  ./replica_sudos.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  krbu (), ruben@brainupdaters.net
#       COMPANY:  BU
#       VERSION:  1.0
#       CREATED:  06/9/2016 16:47:23 PM CEST
#      REVISION:  ---
#===============================================================================
#set -x 

function usage() {

bold=$(tput bold)
none=$(tput sgr0)

echo ""
echo "${bold}Usage: ${0} [OPTIONS...]${none}"
echo ""
echo "${bold}Change Types:${none}"
echo ""
echo "${bold}-u${none} USER         User with admin privileges."
echo "${bold}-S${none} SERVERS      file with the servers to apply."
echo "${bold}-s${none} SUDOS        Comma separated sudo groups list. If this parameter is not specified all files located on /etc/sudoers.d will be processed"
echo ""
echo "${bold}Examples:${none}"
echo ""
echo ""
echo "${bold} ${0} -u user -S servers_list.txt ${none}"
echo ""
echo ""
echo "${bold} ${0} -u user -S servers_list.txt -s monteam,dbateam,unixteam${none}"
echo ""
}

function create_tar_file () {
local SUDOS="$@"
if [[ $EUID -ne 0 ]]
then
        SUDO="sudo"
fi
for sudo_file in ${SUDOS[@]}
do
${SUDO} tar -rPvf /tmp/sudoers_file.tar /etc/sudoers.d/${sudo_file}
done
${SUDO} chmod 666 /tmp/sudoers_file.tar
if [[ $? -eq 0 ]]; then return 0; else return 1;fi
}

function copy_tar_file () {
scp /tmp/sudoers_file.tar ${USER}@${SERVER}:/tmp/.
if [[ $? -eq 0 ]]; then return 0; else return 1;fi
}

function extract_tar () {
${SUDO} /bin/tar -xPvf /tmp/sudoers_file.tar 
${SUDO} /bin/rm /tmp/sudoers_file.tar
}


function ssh_extract_tar () {
local USER=$1
local SERVER=$2
local SUDO=$3
ssh -ttt ${USER}@${SERVER} "$(declare -p SUDO; declare -f extract_tar); extract_tar"
if [ $? -eq 0 ]; then return 0; else return 1; fi
}

while getopts ":u:S:s:" option; do

        case ${option} in
                        u)
                                if [ -n "${OPTARG}" ] && [[ ${OPTARG} != -? ]]
                                then
                                        USER="${OPTARG}"
                                else
                                        echo "${PROGRAM}: -${option} needs a valid argument"     
                                        usage
                                        exit 1
                                fi
                                ;;
                        S)
                                if [ -n "${OPTARG}" ] && [[ ${OPTARG} != -? ]]
                                then
                                        SERVERS="${OPTARG}"
                                else
                                        echo "${PROGRAM}: -${option} needs a valid argument"     
                                        usage
                                        exit 1
                                fi
                                ;;
                        s)
                                if [ -n "${OPTARG}" ] && [[ ${OPTARG} != -? ]]
                                then
                                        SUDOS=( $(echo "${OPTARG}" | tr "," " ") )
                                else
                                        echo "${PROGRAM}: -${option} needs a valid argument"     
                                        usage
                                        exit 1
                                fi
                                ;;

                        \?)
                                echo "${PROGRAM}: Invalid option: -${OPTARG}" >&2
                                usage
                                exit 1
                                ;;
                        :)
                                echo "${PROGRAM}: Option -${OPTARG} requires an argument." >&2
                                usage
                                exit 1
                                ;;
        esac
done

if [[ -z "${USER}" || -z "${SERVERS}" ]] 
then
        usage
        exit 1
fi

# si l'usuari no es root carreguem la variable sudo 

if [[ $EUID -ne 0 ]]
then
  	SUDO="sudo" 
fi

if [[ -z "${SUDOS}" ]]
then
	SUDOS=$(${SUDO} ls /etc/sudoers.d)
fi
DATE=$(date +"%Y-%m-%d")
LOGFILE=$0.${DATE}.log
echo ${USER}
echo ${SERVERS}
echo ${SUDOS[*]}

create_tar_file "${SUDOS[*]}" 
for SERVER in $(cat ${SERVERS})
do
	if copy_tar_file ${USER} ${SERVER}; then echo "tar file copied on ${SERVER}" >> ${LOGFILE}; else "Error copying tar file on ${SERVER}" >> ${LOGFILE}; fi
	if ssh_extract_tar ${USER} ${SERVER} ${SUDO}; then echo "tar file extracted succesfully on ${SERVER}" >> ${LOGFILE}; else "Error extracting tar file on ${SERVER}" >> ${LOGFILE}; fi 
done

#if delete_tar_file; then echo "tar file has been deleted" >> ${LOGFILE}; else "Error deleting tar file" >> ${LOGFILE}; fi
${SUDO} rm /tmp/sudoers_file.tar
