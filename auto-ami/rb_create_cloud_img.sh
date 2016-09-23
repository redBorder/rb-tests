#!/bin/bash 

function modify_isolinux_files {
    sed -i '/menu default/d' modifiediso/isolinux/isolinux.cfg
    sed -i 's/ks-.*.cfg$/ks.cfg/g' modifiediso/isolinux/isolinux.cfg
    sed -i 's/timeout 600/timeout 10/g' modifiediso/isolinux/isolinux.cfg
}
function modify_ks_files {
    grep -q "^keyboard" ks.cfg
    [ $? -ne 0 ] && sed -i '1ikeyboard us' ks.cfg
    grep -q "^timezone" ks.cfg
    [ $? -ne 0 ] && sed -i '1itimezone --utc GMT' ks.cfg
    grep -q "^lang" ks.cfg
    [ $? -ne 0 ] && sed -i '1ilang en_US.UTF-8' ks.cfg
    sed -i '/timezone --utc GMT/i rootpw "redborder"' ks.cfg
}


release=$1
temp_folder=temp

rm -rf $temp_folder
mkdir $temp_folder
chown rb-tests:rb-tests $temp_folder
cd $temp_folder
wget -O $release.iso http://webnas.redborder.lan/pandora/isos/redBorder-isos/$release.iso

if [ "x$release" != "x" ] ; then	
    mkdir mountediso
    mount -o loop $release.iso mountediso/
    rm -rf modifiediso
    mkdir modifiediso
    rsync -av mountediso/ modifiediso/
    umount mountediso
        
     #if ks.cfg exist in root directory, directly modify files
    if [ -f modifiediso/ks.cfg  ] ; then
        echo -n "Modifying isolinux.cfg... "
        modify_isolinux_files
        echo "finish"
        echo -n "Modifying directly ks.cfg... "
        cd modifiediso; modify_ks_files; cd ..
        echo "finish"
    else
        cd modifiediso
        echo -n "Uncompressing initrd.img... "
        initrd_img="$(pwd)/isolinux/initrd.img"
        my_initrd_dir=$(mktemp -d /tmp/initrd-XXXX)
        cp $initrd_img $my_initrd_dir/initrd.img.xz
        xz --format=lzma $my_initrd_dir/initrd.img.xz --decompress
        mkdir $my_initrd_dir/initrd
        pushd $my_initrd_dir/initrd &>/dev/null
        cpio -ivdum < ../initrd.img &> /dev/null
        rm -f $initrd_img
        echo "finish"
        ######
        echo -n "Modifying ks files... "
        modify_ks_files
        echo "finish"
        ######
        echo -n "Compressing initrd.img..."
        find . -print |cpio -o -H newc 2>/dev/null | xz --format=lzma > $initrd_img
        popd &> /dev/null
        rm -rf $my_initrd_dir
        echo "finish"
        cd ..
        echo -n "Modifying isolinux files... "
        modify_isolinux_files $RB_MODE
        echo "finish"
    fi
    rm -f redBorder-*
    cd modifiediso		
    mkisofs -o ../cloud_$release.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V "asdf" .
    cd ..
    rm -rf mountediso
    rm -rf modifiediso
    qemu-img create $release.img 12G
    qemu-system-x86_64 -boot d -cdrom cloud_$release.iso -m 1024 -hda $release.img -no-reboot -enable-kvm -k es -vnc :6001 -usbdevice tablet
    echo "Creating qcow2 image"
    qemu-img convert -f raw -O qcow2 $release.img $release.qcow2
    echo "Creating vmdk image"
    qemu-img convert -f raw -O vmdk  $release.img $release.vmdk
    chown rb-tests:rb-tests $release.img
else
    echo "Bad arguments, redBorder release is needed"
fi
cd ..

