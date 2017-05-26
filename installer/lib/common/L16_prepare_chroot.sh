prepare_chroot_prepare(){
    #this function prepare the chroot
    #mounts /proc /dev /sys
    #cp resolv.conf and  fstab
    #cp the configuration in /root
    #$1 ->the configuration file

    config_file=$1

    mount -t proc none $GLOBAL_INSTALL_DIR/proc 
    mount -o rbind /dev $GLOBAL_INSTALL_DIR/dev
    mount -o rbind /sys $GLOBAL_INSTALL_DIR/sys
    cp /etc/resolv.conf $GLOBAL_INSTALL_DIR/etc/
    cp /etc/fstab $GLOBAL_INSTALL_DIR/etc/
    cp -r $GLOBAL_BASE_DIR_INSTALLER $GLOBAL_INSTALL_DIR/$GLOBAL_CHROOT_DIR_INSTALLER
    cp $config_file $GLOBAL_INSTALL_DIR/root
    cp -R $GLOBAL_SPLITTED_DIR $GLOBAL_INSTALL_DIR/$GLOBAL_SPLITTED_DIR
}
