#!/bin/bash

pushd `dirname $0` > /dev/null

config_folder=config

#Config default values
temp_folder=temp
manager_public_key=""
manager_public_key2=""
disk_size="30G"
lockfile="/tmp/rb_create_img.lock"


#Checking configuration
if [ -f $config_folder/rb_create_img_cp.conf  ] ; then  
    source $config_folder/rb_create_img_cp.conf
else 
    echo "Config file not found"
    STATUS=1
    exit $STATUS
fi

lockfile="/tmp/rb_create_img.lock"
function f_trap_exit() {
    rm -f $lockfile
    exit $STATUS
}
function f_trap_hup() {
    kill $$
}

function check_rb_create_img_process() {
    if [ -f $lockfile ] ; then
        creatorpid=$(head -n 1 $lockfile)
        if [ "x$creatorpid" != "x" -a -f /proc/$creatorpid/cmdline ]; then
            strings /proc/$creatorpid/cmdline | grep -q 'rb_create_img.sh'
            if [ $? -eq 0 ] ; then
                echo "INFO : this rb_create_img.s is locked ($lockfile - pid: $creatorpid)" 
                return 255
            fi
        fi
    fi 
    return 0
}
 
function usage {
    echo "USAGE: $(basename $0) <OPTIONS>"
    echo "-u <URL>: url of iso image"
    echo "-f <PATH>: path of iso image"
    echo "-m : mode MANAGER (default)"
    echo "-i : mode IPS"
    echo "-c : mode CLIENTPROXY"
    echo "-w : mode MALWARE"
    echo "-s : mode MASTER"
    echo "-n <MODE> : custom indicated mode"
    
    echo "Example: $(basename $0) -f redborder.iso"
    echo "Example: $(basename $0) -u http://redborder.com/isos/redborder.iso"
}

function modify_isolinux_files { 
    RB_MODE=$1 #path in with ks.cfg is located
    sed -i '/menu default/d' modifiediso/isolinux/isolinux.cfg
    sed -i 's/ks-.*.cfg$/ks.cfg/g' modifiediso/isolinux/isolinux.cfg
    if [ "x$RB_MODE" == "xCLIENTPROXY" ] ; then
        sed -i '/Install Client ^Proxy/a menu default' modifiediso/isolinux/isolinux.cfg
    elif [ "x$RB_MODE" == "xIPS" ] ; then
        sed -i '/Install ^Sensor IPS/a menu default' modifiediso/isolinux/isolinux.cfg
    elif [ "x$RB_MODE" == "xMALWARE" ] ; then
	sed -i  '/Install Manager + mal^ware (beta)/a menu default' modifiediso/isolinux/isolinux.cfg
    else #defalut is manager or master
        sed -i '/Install ^Manager/a menu default' modifiediso/isolinux/isolinux.cfg 
    fi
    sed -i 's/timeout 600/timeout 10/g' modifiediso/isolinux/isolinux.cfg
}

function modify_ks_files {
    RB_MODE=$1
    if [ "x$RB_MODE" == "xCLIENTPROXY" ] ; then
        rm -f ks.cfg &> /dev/null
        cp ks-proxy.cfg ks.cfg
    elif [ "x$RB_MODE" == "xIPS" ] ; then
        rm -f ks.cfg &> /dev/null
        cp ks-sensor.cfg ks.cfg
        # IPS management interface configuration
        echo -e 'cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0' >> ks.cfg
        echo -e 'TYPE=Ethernet' >> ks.cfg
        echo -e 'DEVICE=eth0' >> ks.cfg
        echo -e 'BOOTPROTO=dhcp' >> ks.cfg
        echo -e 'ONBOOT=yes' >> ks.cfg
        echo -e 'EOF' >> ks.cfg
    elif [ "x$RB_MODE" == "xMALWARE" ] ; then
      rm -f ks.cfg &> /dev/null
      cp ks-manager-malware.cfg ks.cfg
    else #default is manager
      rm -f ks.cfg &> /dev/null
      cp ks-manager.cfg ks.cfg
    fi

    grep -q "^keyboard" ks.cfg
    [ $? -ne 0 ] && sed -i '1ikeyboard us' ks.cfg
    grep -q "^timezone" ks.cfg
    [ $? -ne 0 ] && sed -i '1itimezone --utc GMT' ks.cfg
    grep -q "^lang" ks.cfg
    [ $? -ne 0 ] && sed -i '1ilang en_US.UTF-8' ks.cfg
    sed -i '/timezone --utc GMT/i rootpw "redborder"' ks.cfg
    sed -i '/hostname rbmanager/i echo "initctl start jenkins-swarm" >> /etc/rc.local' ks.cfg
    sed -i '/hostname rbmanager/i cp /tempdir/swarm/swarm-client-2.0-jar-with-dependencies.jar /root' ks.cfg
    sed -i '/hostname rbmanager/i cp /tempdir/swarm/jenkins-swarm.conf /etc/init' ks.cfg
    echo -e '\n mkdir -p /root/.ssh\n' >> ks.cfg
    echo -e 'chmod 755 /root/.ssh' >> ks.cfg
    echo -e 'cat <<EOF >> /root/.ssh/authorized_keys2' >> ks.cfg
    echo -e "$manager_public_key" >> ks.cfg
    echo -e "$manager_public_key2" >> ks.cfg
    echo -e 'EOF' >> ks.cfg
}

#Default variable values
ISO=""
URL=""
filename=""
RB_MODE=""
STATUS=0

#MAIN EXECUTION

#Capturing signals
trap 'f_trap_exit' 0 15
trap 'f_trap_exit' SIGTERM

pushd `dirname $0` > /dev/null

#Checking if rb_create_img is being executed
check_rb_create_img_process
CHECK_PROCESS=$?
COUNTER=1
while [ $CHECK_PROCESS -ne 0 ] ; do
  if [ $COUNTER -le 30 ] ; then
    echo "Waiting 60 seconds for rb_create_img.sh to be unlocked... ($COUNTER/30)"
    let COUNTER=COUNTER+1    
    sleep 60
    check_rb_create_img_process
    CHECK_PROCESS=$?
  else 
    STATUS=255
    exit $STATUS
  fi
done 

#create pid file
echo $$ > $lockfile


#Options management
while getopts ":u:f:micwsn:" opt ; do
    case $opt in
        u) URL=$OPTARG;;
        f) ISO=$OPTARG;;
        m) [ "x$RB_MODE" == "x" ] && RB_MODE="MANAGER";;
        i) [ "x$RB_MODE" == "x" ] && RB_MODE="IPS";;
        c) [ "x$RB_MODE" == "x" ] && RB_MODE="CLIENTPROXY";;
        w) [ "x$RB_MODE" == "x" ] && RB_MODE="MALWARE";;
        s) [ "x$RB_MODE" == "x" ] && RB_MODE="MASTER";;
        n) [ "x$RB_MODE" == "x" ] && RB_MODE=$OPTARG;;
        g) disk_size=$OPTARG;;
    esac
done

[ "x$RB_MODE" == "x" ] && RB_MODE="MANAGER"
echo "SELECTED $RB_MODE REDBORDER MODE"

#Checking if temp_folder exists. If not, it will be created
if [ ! -d $temp_folder ] ; then
    mkdir $temp_folder
fi

if [ "x$ISO" != "x" -a "x$URL" = "x" ] ; then
    #Checking if file exists
    if [ ! -f $ISO ] ; then
        echo "ERROR: iso file ($ISO) do not exist"	
        STATUS=1
	exit $STATUS;
    else
        filename=$(basename "$ISO")
    fi   
elif [ "x$URL" != "x" -a "x$ISO" = "x" ] ; then
    rm -rf *.iso
    filename=$(basename "$URL")
    wget -O $temp_folder/$filename $URL
    if [ $? -ne 0 ] ; then
        echo "ERROR: can't obtain iso file from url $URL"
        STATUS=2
        exit $STATUS;
    fi 
else 
    echo "ERROR: you must select -u or -i option. You can't use both or any"
    usage
    STATUS=3
    exit $STATUS
fi

if [ "x$filename" != "x" ] ; then
    isoname=$(basename -s .iso $filename)    
    
    #Mounting iso
    cd $temp_folder
    rm -rf mountediso
    mkdir mountediso
    mount -o loop $filename mountediso/
    rm -rf modifiediso
    mkdir modifiediso
    echo -n "Copying iso files... "
    rsync -av mountediso/ modifiediso/ &> /dev/null
    echo -n "Including swarm jar file"
    mkdir modifiediso/swarm
    cp ../swarm/* modifiediso/swarm
    umount mountediso 
    echo "finish"

    #if ks.cfg exist in root directory, directly modify files
    if [ -f modifiediso/ks.cfg  ] ; then 
        echo -n "Modifying directly ks.cfg... "
        cd modifiediso; modify_ks_files $RB_MODE; cd .. 
        echo -n "Modifying isolinux files... "
        modify_isolinux_files $RB_MODE        
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
        modify_ks_files $RB_MODE
        echo "finish"
        ######
        echo -n "Compressing initrd.img..."
        find . -print |cpio -o -H newc 2>/dev/null | xz --format=lzma > $initrd_img
        popd &> /dev/null
        #rm -rf $my_initrd_dir
	echo "finish"
        cd ..
        echo -n "Modifying isolinux files... "
        modify_isolinux_files $RB_MODE
        echo "finish"
    fi

    rm -f TEST_redBorder*
    cd modifiediso
    echo -n "Generating modified iso... "
    mkisofs -o ../TEST_$RB_MODE\_$filename -b isolinux/isolinux.bin -c isolinux/boot.cat -quiet -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V "asdf" .
    echo "finish"
    cd ..

    #Cleaning...
    rm -rf modifiediso
    rm -rf mountediso
    #Create virtual IMG with redBorder Manager installation
    [ "x$RB_MODE" == "xMALWARE" ] && disk_size="80G"      
    qemu-img create TEST_$RB_MODE\_$isoname.img $disk_size
    #Installing redBorder
    qemu-system-x86_64 -boot d -cdrom TEST_$RB_MODE\_$filename -m 1024 -hda TEST_$RB_MODE\_$isoname.img -no-reboot -enable-kvm -k es -vnc :100 -usbdevice tablet
    cd ..
else
    echo "Bad arguments"
    usage
fi
popd > /dev/null 

