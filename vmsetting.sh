#!/bin/bash

echo "clearing last vm data..."

pattern="alpine"
filtered_vms=$(VBoxManage list vms | grep $pattern | awk -F'"' '{print $2}')
for vm in $filtered_vms; do
    echo "removing $vm"
    VBoxManage unregistervm "$vm" --delete
    sleep 1
done
echo "clearing last vm data done"


UTILS_PATH=$(find -L ~ -name "utils_func.sh" -type f 2>/dev/null)

if [ -z "$UTILS_PATH" ]; then
    echo "utils_func.sh not found in home directory."
    exit 1
fi

source "$UTILS_PATH"
# Oracle VM VirtualBox 자동 설정 스크립트

# 설정 변수

curl --remote-name https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-standard-3.21.3-x86_64.iso
ISO_PATH=$(find -L ~ -name "alpine-standard-3.21.3-x86_64.iso" -type f 2>/dev/null)
if [ -z "$ISO_PATH" ]; then
    echo "alpine-standard-3.21.3-x86_64.iso not found in home directory."
    exit 1
fi

# quick mode
echo "Do you want to use quick mode? (y/n): "
read -r QUICK_MODE

if [ "$QUICK_MODE" = "y" ]; then
    echo "startoing quick mode"
    echo "vm name: alpineServer"
    echo "Memory size: 2048MB"
    echo "CPU count: 2"
    echo "Disk size: 8192MB"
    VM_NAME="alpineServer"
    MEMORY_MB=2048
    CPU_COUNT=2
    DISK_SIZE_MB=8192
else
# setting vmname
  echo "Starting insert mode"
  echo "insert vm name: "
  read -r MIDDLE
  INITIAL="alpine"
  VM_NAME="${INITIAL}_${MIDDLE}"
  OS_TYPE="Linux_64"
  echo "insert memoty size(si is mb): "
  read -r MEMORY_MB
  echo "insert cpu count: "
  read -r CPU_COUNT
  echo "insert Disk size(si is mb): "
  read -r DISK_SIZE_MB
fi


# 경로설정은 아직 구체적으로 바꿀 의향 없음
VM_BASE_PATH="/home/$USER/goinfre/inception_d"

# VM 생성
VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --basefolder "$VM_BASE_PATH" --register

# 메모리 및 CPU 설정
VBoxManage modifyvm "$VM_NAME" --memory "$MEMORY_MB" --cpus "$CPU_COUNT" --pae on

# 네트워크 설정 (NAT)
VBoxManage modifyvm "$VM_NAME" --nic1 nat

# 저장소 컨트롤러 생성
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAHCI

# 하드 디스크 생성 및 연결
VBoxManage createhd --filename "$VM_NAME.vdi" --size "$DISK_SIZE_MB"
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_NAME.vdi"

# ISO 이미지 연결 (설치용)
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$ISO_PATH"

# 부팅 순서 설정
VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# VM 시작
VBoxManage startvm "$VM_NAME"

echo "VM $VM_NAME이 생성되고 시작되었습니다."

# VM root로그인

echo "VM $VM_NAME이 확실한 실행을 위해서 설치를 위해서 40초동안 기다립니다."
progress_bar 40

vboxmanage controlvm "$VM_NAME" keyboardputstring "root"
ENTER

#answer file 생성
vboxmanage controlvm "$VM_NAME" keyboardputstring "cat > answer.conf << 'EOF'"
ENTER

vboxmanage controlvm "$VM_NAME" keyboardputstring "KEYMAPOPTS=\"kr kr-kr104\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "HOSTNAMEOPTS=\"-n ${VM_NAME}\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "INTERFACESOPTS=\"auto lo"
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "iface lo inet loopback"
ENTER
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "auto eth0"
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "iface eth0 inet dhcp\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "TIMEZONEOPTS=\"-z Japan\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "PROXYOPTS=\"none\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "APKREPOSOPTS=\"-r\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "SSHDOPTS=\"-c openssh\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "NTPOPTS=\"-c chrony\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "USEROPTS=\"none\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "DISKOPTS=\"-m sys -s 0 -v /dev/sda\""
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "EOF"
ENTER


vboxmanage controlvm "$VM_NAME" keyboardputstring "setup-alpine -f answer.conf -e"
ENTER
echo "초기 설정중입니다. 기다려 주세요"
progress_bar 180 &  # 백그라운드에서 실행
progress_pid=$! 

sleep 40
#여기서 reboot를 시키고 다시 로그인하는 과정을 추가 해야한다.
vboxmanage controlvm "$VM_NAME" keyboardputstring "y"
ENTER

wait $progress_pid

# VM 이미지 링크를 해제하는 중!
vmpoweroff
echo "VM $VM_NAME의 ISO 링크를 해제하는 중입니다."
vboxmanage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium none

rm -rf $ISO_PATH

echo "VM $VM_NAME의 ISO 링크 해제중입니다. 기다려 주세요"
progress_bar 20

echo "VM $VM_NAME의 ISO 링크 해제가 완료되었습니다."
echo "VM $VM_NAME을 재부팅합니다."
vboxmanage startvm "$VM_NAME"

echo "VM $VM_NAME 이 재부팅되었습니다. 40초 기다려 주세요"
progress_bar 40
vboxmanage controlvm "$VM_NAME" keyboardputstring "root"
ENTER

vboxmanage controlvm "$VM_NAME" keyboardputstring "echo \"http://dl-cdn.alpinelinux.org/alpine/v3.21/community\" >> /etc/apk/repositories"  
ENTER

# #VM apk 저장소 활성화
# vboxmanage controlvm "$VM_NAME" keyboardputstring "echo \"http://dl-cdn.alpinelinux.org/alpine/v3.21/main\" >> /etc/apk/repositories"                          
# ENTER
# vboxmanage controlvm "$VM_NAME" keyboardputstring "echo \"http://dl-cdn.alpinelinux.org/alpine/v3.21/community\" >> /etc/apk/repositories"  
# ENTER 
# #VM 네트워크 워크 활성화
# vboxmanage controlvm "$VM_NAME" keyboardputstring "ip link set eth0 up"
# ENTER
# vboxmanage controlvm "$VM_NAME" keyboardputstring "udhcpc -i eth0"
# ENTER 
# #VM에 패키지를 다운 받기위한 apk 업데이트
vboxmanage controlvm "$VM_NAME" keyboardputstring "apk update && apk upgrade"
ENTER 
echo "패키지를 업데이트 중 입니다. 기다려 주세요"
progress_bar 10

#VM 을 효율적으로 control 하기위한 virtualbox-guest-additions 설치
# https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-guestcontrol.html
# https://wiki.alpinelinux.org/wiki/VirtualBox_guest_additions
# 실행 방법
vboxmanage controlvm "$VM_NAME" keyboardputstring "apk add virtualbox-guest-additions"
ENTER
echo "virtualbox-guest-additions 설치 중입니다. 기다려 주세요"
progress_bar 10

# guest-additions 를 실행하기
vboxmanage controlvm "$VM_NAME" keyboardputstring "rc-service virtualbox-guest-additions start"
ENTER
# guest-additions 를 부팅될때 실행 되도록 설정하기
vboxmanage controlvm "$VM_NAME" keyboardputstring "rc-update add virtualbox-guest-additions boot"
ENTER
# guestcontrol과 쉘 명령어 조합으로 apk update && upgrade 실행
vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/bin/sh" -- -c "apk update && apk upgrade"

# 패키지 설치가 잘되고 패키지의 지연을 해결하기 위한 sh file만들기 local 과 vm에 설치가 된다.
cat > "$VM_BASE_PATH/setup_packages.sh" << 'EOF'
#!/bin/sh

install_and_verify() {
  local pkg=$1
  local check_cmd=$2
  local next_step=$3
  
  echo "Installing $pkg..."
  apk add $pkg
  
  echo "Verifying $pkg installation..."
  until eval "$check_cmd"; do
    echo "Waiting for $pkg to be ready..."
    sleep 1
  done
  
  echo "$pkg is ready, proceeding with configuration"
  eval "$next_step"
}

# 인자로 전달된 패키지와 검증 명령, 다음 단계를 실행
if [ $# -ge 3 ]; then
  install_and_verify "$1" "$2" "$3"
else
  echo "사용법: $0 '패키지명' '검증명령어' '다음단계명령어'"
  exit 1
fi

echo "패키지 설치 및 설정이 완료되었습니다!"
EOF

vboxmanage guestcontrol "$VM_NAME" copyto "$(pwd)/setup_packages.sh" /root/setup_packages.sh --username root
vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/bin/sh" -- -c "chmod +x /root/setup_packages.sh"
#복사가 될때 기다리는시간
sleep 3

vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/root/setup_packages.sh" -- "expect" "apk info -e expect && which expect > /dev/null 2>&1" "echo ok"
vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/root/setup_packages.sh" -- "ufw" "apk info -e ufw && which ufw > /dev/null 2>&1" "ufw default deny && ufw enable && ufw allow 80 && ufw allow 4242 ; rc-update add ufw"
vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/root/setup_packages.sh" -- "docker" "apk info -e docker && which docker > /dev/null 2>&1" "rc-update add docker default && service docker start && docker run hello-world"
vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/root/setup_packages.sh" -- "docker-compose" "apk info -e docker-compose && which docker-compose > /dev/null 2>&1" "echo ok"

echo "재부팅 하겠습니다!"
vboxmanage guestcontrol "$VM_NAME" run --exe "/sbin/reboot" --username root -- ""
progress_bar 60

vboxmanage controlvm "$VM_NAME" keyboardputstring "root"
ENTER

vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/bin/sed" -- -i "s/^#Port 22/Port 4242/1" /etc/ssh/sshd_config
progress_bar 3
vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/bin/sed" -- -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/1" /etc/ssh/sshd_config
progress_bar 3
echo "ssh 설정중입니다. 기다려 주세요"
vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/bin/sed" -- -i "s/^#PasswordAuthentication yes/PasswordAuthentication yes/1" /etc/ssh/sshd_config
progress_bar 3

vboxmanage guestcontrol "$VM_NAME" run --username root --exe "/sbin/rc-service" -- sshd restart

# 비밀번호 설정 port fowarding을 하기위해서 비밀번호를 설정합니다. 초기비밀번호는 a123456789 입니다.
vboxmanage controlvm "$VM_NAME" keyboardputstring "passwd"
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "a123456789"
ENTER
progress_bar 2
vboxmanage controlvm "$VM_NAME" keyboardputstring "a123456789"
ENTER

# port Forwarding 설정 을 위해 VM을 종료합니다.
vmpoweroff
echo "VM $VM_NAME을 종료합니다."

echo "Port Forwarding 설정을 시작합니다."
VMIP=$(vboxmanage guestproperty enumerate alpineServer | grep "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{print $3}' | tr -d \')
vboxmanage modifyvm "$VM_NAME" --natpf1 "guestssh,tcp,,8080,"${VMIP}",4242"
progress_bar 5

echo "Port Forwarding 설정이 완료되었습니다."
# echo "VM $VM_NAME을 재부팅합니다."
# progress_bar 40
# vboxmanage startvm "$VM_NAME"
# progress_bar 40
# vboxmanage controlvm "$VM_NAME" keyboardputstring "root"
# ENTER
# vboxmanage controlvm "$VM_NAME" keyboardputstring "a123456789"
# ENTER


echo "이 밑에서 부터는 스스로 하는 사람이 되길"
echo "Back ground으로 ssh 접속을 시도합니다."
vboxmanage startvm "$VM_NAME" --type headless
progress_bar 40
vboxmanage controlvm "$VM_NAME" keyboardputstring "root"
ENTER
vboxmanage controlvm "$VM_NAME" keyboardputstring "a123456789"
ENTER

echo "포트포워딩을 시작하세요"
# Back ground에서 돌아가는 VM 을 종료하고 싶다면?? vboxmanage controlvm "$VM_NAME" poweroff 하면된다.
# WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED! 오류 발생시
# ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "[127.0.0.1]:8080"
# echo "VM $VM_NAME 포트포워딩을 시작합니다."
# HOSTIP=$(ip addr show lo | grep "inet " | awk '{print $2}' | awk -F'/' '{print $1}')
# ssh -p 8080 root@${HOSTIP}
# echo "ssh -p 8080 root@${HOSTIP}로 ssh 접속을 시도합니다."
# echo "root 와 비밀번호를 입력하세여"


#