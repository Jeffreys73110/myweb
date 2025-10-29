#!/bin/bash

REMOTE_HOST=192.168.1.100
REMOTE_PORT=22
REMOTE_SSH_ACCOUNT=ubuntu
REMOTE_SSH_PASSWORD="12345"
REMOTE_WORKDIR=/home/$REMOTE_SSH_ACCOUNT/temp

SSH_PARAM="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o CheckHostIP=yes"
remote_ssh() {
    cmd=$1
    sshpass -p "$REMOTE_SSH_PASSWORD" ssh -p $REMOTE_PORT -o StrictHostKeyChecking=no $REMOTE_SSH_ACCOUNT@$REMOTE_HOST $cmd
    if [ $? -ne 0 ]; then echo "failed to ssh -p $REMOTE_PORT $REMOTE_SSH_ACCOUNT@$REMOTE_HOST \"$cmd\""; exit -1; fi

    return 0
}

remote_scp() {
    cp_from=$1
    cp_to=$2
    sshpass -p "$REMOTE_SSH_PASSWORD" scp -P $REMOTE_PORT $SSH_PARAM -r $cp_from $cp_to
    if [ $? -ne 0 ]; then echo "failed to scp -P $REMOTE_PORT $cp_from $cp_to"; exit -1; fi

    return 0

    # example:
    # remote_ssh "echo $REMOTE_SSH_PASSWORD | sudo -S sh -c \"echo abc | sudo tee /temp/abc >> /dev/null\""
}

remote_rsync() {
    rsync_from=$1
    rsync_to=$2

    sshpass -p "$REMOTE_SSH_PASSWORD" rsync -avz --delete --progress -e "ssh -p $REMOTE_PORT $SSH_PARAM" install_a5gc/ $rsync_from $rsync_to
    if [ $? -ne 0 ]; then echo "failed to rsysnc $rsync_from $rsync_to"; exit -1; fi

    return 0

    # -a: Archive mode, which preserves permissions, symbolic links, and other attributes.
    # -v: Verbose mode, which provides detailed information about the file transfer process.
    # -z: Compress file data during the transfer.
    # -e "ssh -p 2222": Specifies the SSH command and port to use (2222 in this example).
    # Additional Options:
    # --delete: Delete files in the destination directory that are not present in the source directory.
    # --progress: Show progress during transfer.

    # example:
    # remote_rsync "localdir/" "$REMOTE_SSH_ACCOUNT@$REMOTE_HOST:remotedir/"
}