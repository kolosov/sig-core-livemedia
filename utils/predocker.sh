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



function patch_config {
  echo "New docker path is $1"
  new_dock_dir=$1
  #enable docker settings
  #sed "s~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -G $new_dock_dir~" /tmp/docker.service
  sed -i "s~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -G $new_dock_dir~" /usr/lib/systemd/system/docker.service
  systemctl daemon-reload
  systemctl start docker
}

#find docker dir, argument is a dir list
function find_docker_dir_by_filelist {
#  echo $1
  dir_list=`cat $1`

  for dir in $dir_list
  do
#    echo "Checking: $dir"
    if [ -e "$dir/$mark_filename" ]
    then
#      echo "Dir was found: $dir"
      lmark_dir=$dir
	  echo $lmark_dir
      return 0
    fi
  done
  echo "FALSEEE"
  return 1
}


if [[ -z "$mark_dir" ]]
then
  echo "Dir was not set, try looking for the dir"
  echo "1. Checking for already mounted drives"
  df | awk '{print $6}' |sort|uniq > /tmp/mounted_dirs1

#  mlist=`cat /tmp/mounted_dirs`

  echo "Find for /tmp/mounted_dirs1"
  found_place=$(find_docker_dir_by_filelist "/tmp/mounted_dirs1")
  ret_val=$?
  echo "found_place = $found_place"
  if [ "$ret_val" -eq "0" ]
  then
    echo "Dir was found, patching"
    patch_config $found_place

    exit 0
  fi
  
  

  echo "2. Looking for unmounted drives and mount"
  #get mounted
  mount | cut -d\  -f 1|sort|uniq > /tmp/mounted_disks

  #get all disks
  lsblk -lp|grep part|cut -d\  -f 1|sort > /tmp/all_disks

  #get needed
  comm -13 /tmp/mounted_disks /tmp/all_disks > /tmp/need_disks

  flist=`cat /tmp/need_disks`
  

  echo -n > /tmp/mounted_dirs2
  #mount found disks and prepare file list
  for disk in $flist
  do
    #echo mkdir /mnt/${disk:5}
    #echo mount $disk /mnt/${disk:5}
    mkdir /mnt/${disk:5}
    mount $disk /mnt/${disk:5}
    echo /mnt/${disk:5} >> /tmp/mounted_dirs2
  done

  echo "Find for /tmp/mounted_dirs2"
  found_place=$(find_docker_dir_by_filelist "/tmp/mounted_dirs2")
  ret_val=$?
  echo "found_place = $found_place"
  if [ "$ret_val" -eq "0" ]
  then
    echo "Dir was found, patching"
    patch_config $found_place

    exit 0
  fi

  echo "Dir was not found, set it as parameter: ./predocker -d docker_data_directory"
  exit 1
fi


