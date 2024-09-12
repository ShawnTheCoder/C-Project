#!/bin/sh
jobid="`echo ${SLURM_JOB_ID}|grep -o '[0-9]\+' | head -1`"
path=""
if [ "${1}" != "" ]; then
    path=${1}
else
    echoerr "app/workdir not specified"
    exit -1
fi


#if [ "${2}" != "" ]; then
#    cfxpath=${2}
#    rm -rf ${HOME}/.hostinfo.ccl
#    /data/apps/paracloud/visdesktop/cfx_host_list.sh ${path}/hostlist.txt ${cfxpath} ${path}/hostinfo.ccl
#fi

rm -rf /tmp/.X*

if [ ! -d ~/.vnc/ ]
then
    mkdir ~/.vnc/
fi

VNC=${VNC:-1}

export VGL_DISPLAY=:0

PASSWD_FILE="${HOME}/.vnc/passwd.${jobid}"

echo $PASSWD_FILE

#PW=$(`uuidgen`  |md5sum | awk '{print $1}')
PW=$(uuidgen| md5sum | awk '{print $1}')
PW=${PW:0:8}
#echo ${PW}
echo -e "${PW}\n" | /opt/TurboVNC/bin/vncpasswd -f > ${PASSWD_FILE}
chmod 600 ${PASSWD_FILE}

#generate .cfx5rc file
#rm -rf ${HOME}/.cfx5rc
#cfx5rcfile="${HOME}/.cfx5rc"
#cat << "EOF" >> ${cfx5rcfile}
#!/bin/sh
#CFX5_HOSTS_CCL=$PBS_JOBDIR/hostinfo.ccl
#export CFX5_HOSTS_CCL
#EOF

#echo $cfx5rcfile

#cat ${PBS_NODEFILE} > ${path}/hostlist.${PBS_JOBID}.txt

vglrun /opt/TurboVNC/bin/vncserver -geometry ${GEOMETRY:-1024x768} -depth ${DEPTH:-24} -xstartup ${XSTARTUP:-/Share/apps/paratera/visdesktop/xstartup.turbovnc} -rfbauth ${PASSWD_FILE} -nohttpd :$VNC

#disable power saving blank screen and screen saver
gsettings set org.mate.screensaver lock-enabled false
gsettings set org.mate.power-manager lock-blank-screen false
gsettings set org.mate.power-manager lock-use-screensaver false

gsettings set org.mate.power-manager lock-keyring-suspend false
gsettings set org.mate.power-manager lock-keyring-hibernate false
gsettings set org.mate.power-manager lock-suspend false
gsettings set org.mate.power-manager lock-blank-screen false
gsettings set org.mate.power-manager lock-hibernate false 


gsettings set org.gnome.desktop.session idle-delay 0
#vnc_port=$((5900 + $(echo ${vnc_display} | cut -d: -f2)))
vnc_port=$((5900 + $VNC))
host=$HOSTNAME
TARGET=${host}:${vnc_port}
TOKEN="vncjob_`uuidgen`"
#echo $vnc_port > ~/.vnc/${SLURM_JOB_ID}.vnc

NOVNC_PORT=$((40000+$VNC))

#jobid="`echo ${PBS_JOBID}|grep -o '[0-9]\+' | head -1`"  //move to top by tt
filepath=`pwd`
echo "path=$path"
echo "filepath=$filepath"
vncfile=${path}/.${jobid}.vnc
echo "$vncfile"
echo "{\"password\":\"${PW}\",\"token\":\"${TOKEN}\",\"host\":\"${TARGET}\"}"> ${vncfile}
/usr/share/novnc/utils/launch.sh --listen ${NOVNC_PORT:-40001} --vnc localhost:$vnc_port

