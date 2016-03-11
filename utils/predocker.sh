#!/bin/bash

mark_dir=
mark_filename="USEME"

while getopts ":d:" opt
do
  case $opt in
    d)
      echo "-d was set, using $OPTARG dir" >&2
      mark_dir=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      exit 1
      ;;
   esac
done


if [[ -z "$mark_dir" ]]
then
  echo "Dir was not set, try looking for the dir"
  #get mounted
  mount | cut -d\  -f 1|sort|uniq > /tmp/mounted_disks

  #get all disks
  lsblk -lp|grep part|cut -d\  -f 1|sort > /tmp/all_disks

  #get needed
  comm -13 /tmp/mounted_disks /tmp/all_disks > /tmp/need_disks

  flist=`cat /tmp/need_disks`
  

  for disk in $flist
  do
  #  echo $disk
  #  echo ${disk:5}
    echo mkdir /mnt/${disk:5}
    echo mount $disk /mnt/${disk:5}
  done

  #find the dir

  for dir in /mnt/*
  do
    echo $dir
    if [ -e "$dir/$mark_filename" ]
    then
      echo "Dir was found: $dir"
      mark_dir=$dir
    fi
  done

  if [[ -z "$mark_dir" ]]
  then
    echo "Dir was not found, set it as parameter: ./predocker -d docker_data_directory"
    exit 1
  else
    echo "Dir was found: $mark_dir"
  fi
fi


#enable docker settings
#sed 's/ExecStart=\/usr\/bin\/docker daemon -H fd:\/\//ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -G $mark_dir/' /usr/lib/systemd/system/docker.service
sed "s~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -G $mark_dir~" /tmp/docker.service

systemctl start docker
