#!/bin/bash

usage () { 
  echo "Usage:"
  echo "  ./service.sh -h               Display this help message."
  echo "  ./service.sh [-c] -[i] [-g]   Run CMD in HOST_GROUP."
  echo "Options:"
  echo "  -c command to run in the node"
  echo "  -i ansible inventory path"
  echo "  -g ansible inventory group"
  echo "Author: Mauro Gonzalez (jmajma8@gmail.com)"
}

default_cmd() {
  if [[ -z $1 ]]
  then
    C="/opt/apigee/apigee-service/bin/apigee-all status"     
  else        
    C=$1
  fi
  echo $C
  return 0
}

default_group() {
  if [[ -z $1 ]]
  then
    G="planet"     
  else        
    G=$1
  fi
  echo $G
  return 0
}

while getopts ":c:i:g:h" option
do
  case "$option"
  in
  h ) usage; exit 0;;
  c ) CMD=$OPTARG;;  
  i ) INVENTORY=$OPTARG;;
  g ) GROUP=$OPTARG;; 
  \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
  :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
  *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1
 esac
done

shift $(($OPTIND - 1))
    
if [[ -z $INVENTORY ]]
then  
  usage
  exit 1
else
  echo "Running $(default_cmd "$CMD") in: "
  echo "  $(default_group $GROUP) with inventory: $INVENTORY"  
  ansible -i $INVENTORY $(default_group $GROUP) -m shell \
    -a "$(default_cmd "$CMD")"
fi