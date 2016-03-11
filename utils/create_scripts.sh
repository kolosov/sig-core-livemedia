#!/bin/bash

cat > /usr/bin/predocker.sh << EOF
#!/bin/bash

mark_dir=
mark_filename="USEME"

while getopts ":d:" opt
do
  case \$opt in
    d)
      echo "-d was set, using \$OPTARG dir" >&2
      mark_dir=\$OPTARG
      ;;
    \?)
      echo "Invalid option: -\$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -\$OPTARG requires an argument"
      exit 1
      ;;
   esac
done


if [[ -z "\$mark_dir" ]]
then
  echo "Dir was not set, try looking for the dir"
  #get mounted
  mount | cut -d\  -f 1|sort|uniq > /tmp/mounted_disks

  #get all disks
  lsblk -lp|grep part|cut -d\  -f 1|sort > /tmp/all_disks

  #get needed
  comm -13 /tmp/mounted_disks /tmp/all_disks > /tmp/need_disks

  flist=\`cat /tmp/need_disks\`


  for disk in \$flist
  do
  #  echo \$disk
  #  echo \${disk:5}
    echo mkdir /mnt/\${disk:5}
    echo mount \$disk /mnt/\${disk:5}
  done

  #find the dir

  for dir in /mnt/*
  do
    echo \$dir
    if [ -e "\$dir/\$mark_filename" ]
    then
      echo "Dir was found: \$dir"
      mark_dir=\$dir
    fi
  done

  if [[ -z "\$mark_dir" ]]
  then
    echo "Dir was not found, set it as parameter: ./predocker -d docker_data_directory"
    exit 1
  else
    echo "Dir was found: \$mark_dir"
  fi
fi

#enable docker settings
#sed 's/ExecStart=\/usr\/bin\/docker daemon -H fd:\/\//ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -g $mark_dir/' /usr/lib/systemd/system/docker.service
sed -i "s~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/~ExecStart=\/usr\/bin\/docker daemon -H fd:\/\/ -g \$mark_dir~" /usr/lib/systemd/system/docker.service

systemctl start docker
EOF

chmod a+x /usr/bin/predocker.sh

cat > /usr/bin/testdockx.sh << EOF
#!/bin/bash

docker build --rm -t xclock1 -f /home/Dockerfile .
docker run -ti --rm -e DISPLAY=\$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix xclock1

EOF
chmod a+x /usr/bin/testdockx.sh


cat > /home/Dockerfile << EOF
#!/bin/bash
FROM centos:7
RUN yum install -y xorg-x11-apps
# Replace 0 with your user / group id
RUN export uid=1000 gid=1000
RUN mkdir -p /home/developer
RUN echo "developer:x:\${uid}:\${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd
RUN echo "developer:x:\${uid}:" >> /etc/group
RUN echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN chmod 0440 /etc/sudoers
RUN chown \${uid}:\${gid} -R /home/developer

USER developer
ENV HOME /home/developer
CMD /usr/bin/xclock

EOF

