formatting_wrapper_reiserfs(){
mkfs.reiserfs -f $1
}

formatting_wrapper_ext2(){
mkfs.ext2 $1
}

formatting_wrapper_ext3(){
mkfs.ext3 $1
}

formatting_wrapper_ext4(){
mkfs.ext4 $1
}

formatting_wrapper_xfs(){
mkfs.xfs -f $1
}

formatting_wrapper_swap(){
mkswap $1
}

formating_get_fs_list(){
    #this function just give the list of the fs
    #$1 the cleaned list of partition
    local input_file=$1

    local CLEANED_PARTIONS_FILE=`mktemp`
    common_cleanup_file $input_file  $CLEANED_PARTIONS_FILE

    #partitionning_cleanup $input_file

    local tmp=`mktemp`
    while read -r line
    do
       local fs=`echo $line |cut -d ' ' -f 3` 
       if ! grep -q "^$fs$" $tmp
       then
           echo $fs >>$tmp
       fi
    done < $CLEANED_PARTIONS_FILE
    FS_LIST=`cat $tmp`
    rm $tmp
}

formatting_load_modules(){
    local input_file=$1

    formating_get_fs_list $input_file

    for fs in $FS_LIST

    do
        modprobe $fs
    done

    #we need to wait after loading the fs modules
    #don't ask me why
    sleep 10
}

formatting_format_and_mount(){
    #this script generate the partitionning script
    #$1 -> the partionning file
    local input_file=$1
    local CLEANED_PARTIONS_FILE=`mktemp`
    common_cleanup_file $input_file  $CLEANED_PARTIONS_FILE
    #partitionning_cleanup $input_file

    partitionning_get_disks_list $CLEANED_PARTIONS_FILE
    formatting_load_modules $CLEANED_PARTIONS_FILE
    local MOUNT_POINT_PARTITION_FILE=`mktemp`

    for d in $DEVICE_LIST
    do
        local partition_of_current_disk=`mktemp`
        cat $CLEANED_PARTIONS_FILE |grep "^$d" >$partition_of_current_disk
        local partition_list=`arch_formatting_get_partitions $d`
        
        n=1
        for p in $partition_list
        do
            line=`common_get_line_n $partition_of_current_disk $n`
            mount_point=`echo $line |cut -d ' ' -f 4`
            fs=`echo $line |cut -d ' ' -f 3`
            n=$(( $n + 1 ))
            formatting_wrapper_$fs $p 
            if [ "$fs" = "swap" ]
            then
                swapon $p
                swapdev="$p"
            else
                echo "$mount_point:$p" >> $MOUNT_POINT_PARTITION_FILE
            fi
        done
    done

    echo "#auto-generated fstab" >/etc/fstab
    for m in `sort $MOUNT_POINT_PARTITION_FILE`
    do
        dev=`echo $m|sed "s/.*://"`    
        mount_point="$GLOBAL_INSTALL_DIR/`echo $m|sed "s/:.*//"`"
        mkdir -p $mount_point
        mount $dev $mount_point
        echo "$dev `echo $m|sed "s/:.*//"` auto defaults 0 1" >>/etc/fstab


    done

    echo "$swapdev none swap sw 0 0" >>/etc/fstab
}