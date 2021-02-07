#!/usr/bin/env bash

# Install ansible
if [ "$1" = "-v" ]; then
  ANSIBLE_VERSION="${2}"
fi

yum_makecache_retry() {
  tries=0
  until [ $tries -ge 5 ]
  do
    yum makecache && break
    let tries++
    sleep 1
  done
}

wait_for_cloud_init() {
  while pgrep -f "/usr/bin/python /usr/bin/cloud-init" >/dev/null 2>&1; do
    echo "Waiting for cloud-init to complete"
    sleep 1
  done
}

dpkg_check_lock() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "Waiting for dpkg lock release"
    sleep 1
  done
}

apt_install() {
  dpkg_check_lock && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    -o DPkg::Options::=--force-confold -o DPkg::Options::=--force-confdef "$@"
}

if [ "x$KITCHEN_LOG" = "xDEBUG" ] || [ "x$OMNIBUS_ANSIBLE_LOG" = "xDEBUG" ]; then
  export PS4='(${BASH_SOURCE}:${LINENO}): - [${SHLVL},${BASH_SUBSHELL},$?] $ '
  set -x
fi

if [ ! "$(which ansible-playbook)" ]; then
  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || [ -f /etc/system-release ]; then

    # Install required Python libs and pip
    # Fix EPEL Metalink SSL error
    # - workaround: https://community.hpcloud.com/article/centos-63-instance-giving-cannot-retrieve-metalink-repository-epel-error
    # - SSL secure solution: Update ca-certs!!
    #   - http://stackoverflow.com/q/26734777/645491#27667111
    #   - http://serverfault.com/q/637549/77156
    #   - http://unix.stackexchange.com/a/163368/7688
    yum -y install ca-certificates nss
    yum clean all
    rm -rf /var/cache/yum
    yum_makecache_retry
    yum -y install epel-release
    # One more time with EPEL to avoid failures
    yum_makecache_retry

    yum -y install python-pip PyYAML python-jinja2 python-httplib2 python-keyczar python-paramiko git
    # If python-pip install failed and setuptools exists, try that
    if [ -z "$(which pip)" ] && [ -z "$(which easy_install)" ]; then
      yum -y install python-setuptools
      easy_install pip
    elif [ -z "$(which pip)" ] && [ -n "$(which easy_install)" ]; then
      easy_install pip
    fi

    # Install passlib for encrypt
    yum -y groupinstall "Development tools"
    yum -y install sshpass libffi-devel openssl-devel && pip install pyrax pysphere boto passlib dnspython

    # Install Ansible module dependencies
    yum -y install bzip2 file findutils git gzip hg svn sudo tar which unzip xz zip
    [ ! -n "$(grep ':8' /etc/system-release-cpe)" ] && yum -y install libselinux-python python-devel MySQL-python
    [ -n "$(grep ':8' /etc/system-release-cpe)" ] && yum -y install python36-devel python3-PyMySQL python3-pip
    [ -n "$(yum search procps-ng)" ] && yum -y install procps-ng || yum -y install procps

  elif [ -f /etc/debian_version ] || grep -qi ubuntu /etc/lsb-release || grep -qi ubuntu /etc/os-release; then
    wait_for_cloud_init
    dpkg_check_lock && apt-get update -q

    # Install required Python libs and pip
    apt_install python3-pip python3-yaml python3-jinja2 python3-httplib2 python3-netaddr python3-paramiko python3-pkg-resources libffi-dev python3-all-dev python3-mysqldb python3-selinux python3-boto
    [ "X$?" != X0 ] && apt_install python-pip python-yaml python-jinja2 python-httplib2 python-netaddr python-paramiko python-pkg-resources libffi-dev python-all-dev python-mysqldb python-selinux python-boto
    [ -n "$( dpkg_check_lock && apt-cache search python-keyczar )" ] && apt_install python-keyczar
    dpkg_check_lock && apt-cache search ^git$ | grep -q "^git\s" && apt_install git || apt_install git-core

    # If python-pip install failed and setuptools exists, try that
    if [ -z "$(which pip3)" ] && [ -z "$(which pip)" ] && [ -z "$(which easy_install)" ]; then
      apt_install python-setuptools
      easy_install pip
    elif [ -z "$(which pip3)" ] && [ -z "$(which pip)" ] && [ -n "$(which easy_install)" ]; then
      easy_install pip
    fi
    # If python-keyczar apt package does not exist, use pip
    [ -z "$( apt-cache search python-keyczar )" ] && sudo pip3 install python-keyczar || sudo pip install python-keyczar

    # Install passlib for encrypt
    apt_install build-essential
    if [ ! -z "$(which pip3)" ]; then
      apt_install sshpass
      pip3 install cryptography || pip3 install cryptography==3.2.1
      pip3 install pyrax pysphere boto passlib dnspython pyopenssl
    elif [ ! -z "$(which pip)" ]; then
      apt_install sshpass && pip install pyrax pysphere boto passlib dnspython pyopenssl
    fi

    # Install Ansible module dependencies
    apt_install bzip2 file findutils git gzip mercurial procps subversion sudo tar debianutils unzip xz-utils zip

  elif [ -f /etc/SuSE-release ] || grep -qi opensuse /etc/os-release; then
    zypper --quiet --non-interactive refresh

    # Install required Python libs and pip
    zypper --quiet --non-interactive install libffi-devel openssl-devel python-devel perl-Error python-xml rpm-python
    zypper --quiet --non-interactive install git || zypper --quiet --non-interactive install git-core

    # If python-pip install failed and setuptools exists, try that
    if [ -z "$(which pip)" ] && [ -z "$(which easy_install)" ]; then
      zypper --quiet --non-interactive install python-setuptools
      easy_install pip
    elif [ -z "$(which pip)" ] && [ -n "$(which easy_install)" ]; then
      easy_install pip
    fi

  elif [ -f /etc/fedora-release ]; then
    # Install required Python libs and pip
    dnf -y install gcc libffi-devel openssl-devel python-devel

    # If python-pip install failed and setuptools exists, try that
    if [ -z "$(which pip)" ] && [ -z "$(which easy_install)" ]; then
      dng -y install python-setuptools
      easy_install pip
    elif [ -z "$(which pip)" ] && [ -n "$(which easy_install)" ]; then
      easy_install pip
    fi

  else
    echo 'WARN: Could not detect distro or distro unsupported'
    echo 'WARN: Trying to install ansible via pip without some dependencies'
    echo 'WARN: Not all functionality of ansible may be available'
  fi

  mkdir -p /etc/ansible/
  printf "%s\n" "[local]" "localhost" > /etc/ansible/hosts
  if [ -z "$ANSIBLE_VERSION" -a -n "$(which pip3)" ]; then
    pip3 install -q ansible
  elif [ -n "$(which pip3)" ]; then
    pip3 install -q ansible=="$ANSIBLE_VERSION"
  elif [ -z "$ANSIBLE_VERSION" ]; then
    pip install -q six --upgrade
    pip install -q ansible
  else
    pip install -q six --upgrade
    pip install -q ansible=="$ANSIBLE_VERSION"
  fi
  [ -n "$(grep ':8' /etc/system-release-cpe 2>/dev/null)" ] && ln -s /usr/local/bin/ansible /usr/bin/
  [ -n "$(grep ':8' /etc/system-release-cpe 2>/dev/null)" ] && ln -s /usr/local/bin/ansible-playbook /usr/bin/
  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || [ -f /etc/system-release ]; then
    # Fix for pycrypto pip / yum issue
    # https://github.com/ansible/ansible/issues/276
    if  ansible --version 2>&1  | grep -q "AttributeError: 'module' object has no attribute 'HAVE_DECL_MPZ_POWM_SEC'" ; then
      echo 'WARN: Re-installing python-crypto package to workaround ansible/ansible#276'
      echo 'WARN: https://github.com/ansible/ansible/issues/276'
      pip uninstall -y pycrypto
      yum erase -y python-crypto
      yum install -y python-crypto python-paramiko
    fi
  fi

fi

set -e

# TERRAFORM INSTALLER - Automated Terraform Installation
#   Apache 2 License - Copyright (c) 2018  Robert Peteuil  @RobertPeteuil
#
#     Automatically Download, Extract and Install
#        Latest or Specific Version of Terraform
#
#   from: https://github.com/robertpeteuil/terraform-installer

# Uncomment line below to always use 'sudo' to install to /usr/local/bin/
# sudoInstall=true

scriptname=$(basename "$0")
scriptbuildnum="1.5.4"
scriptbuilddate="2020-06-25"

# CHECK DEPENDANCIES AND SET NET RETRIEVAL TOOL
if ! unzip -h 2&> /dev/null; then
  echo "aborting - unzip not installed and required"
  exit 1
fi

if curl -h 2&> /dev/null; then
  nettool="curl"
elif wget -h 2&> /dev/null; then
  nettool="wget"
else
  echo "aborting - wget or curl not installed and required"
  exit 1
fi

if jq --help 2&> /dev/null; then
  nettool="${nettool}jq"
fi

displayVer() {
  echo -e "${scriptname}  ver ${scriptbuildnum} - ${scriptbuilddate}"
}

usage() {
  [[ "$1" ]] && echo -e "Download and Install Terraform - Latest Version unless '-i' specified\n"
  echo -e "usage: ${scriptname} [-i VERSION] [-a] [-c] [-h] [-v]"
  echo -e "     -i VERSION\t: specify version to install in format '0.11.8' (OPTIONAL)"
  echo -e "     -a\t\t: automatically use sudo to install to /usr/local/bin (or \$TF_INSTALL_DIR)"
  echo -e "     -c\t\t: leave binary in working directory (for CI/DevOps use)"
  echo -e "     -h\t\t: help"
  echo -e "     -v\t\t: display ${scriptname} version"
}

getLatest() {
  # USE NET RETRIEVAL TOOL TO GET LATEST VERSION
  case "${nettool}" in
    # jq installed - parse version from hashicorp website
    wgetjq)
      LATEST_ARR=($(wget -q -O- https://releases.hashicorp.com/index.json 2>/dev/null | jq -r '.terraform.versions[].version' | sort -t. -k 1,1nr -k 2,2nr -k 3,3nr))
      ;;
    curljq)
      LATEST_ARR=($(curl -s https://releases.hashicorp.com/index.json 2>/dev/null | jq -r '.terraform.versions[].version' | sort -t. -k 1,1nr -k 2,2nr -k 3,3nr))
      ;;
    # parse version from github API
    wget)
      LATEST_ARR=($(wget -q -O- https://api.github.com/repos/hashicorp/terraform/releases 2> /dev/null | awk '/tag_name/ {print $2}' | cut -d '"' -f 2 | cut -d 'v' -f 2))
      ;;
    curl)
      LATEST_ARR=($(curl -s https://api.github.com/repos/hashicorp/terraform/releases 2> /dev/null | awk '/tag_name/ {print $2}' | cut -d '"' -f 2 | cut -d 'v' -f 2))
      ;;
  esac

# make sure latest version isn't beta or rc
for ver in "${LATEST_ARR[@]}"; do
  if [[ ! $ver =~ beta ]] && [[ ! $ver =~ rc ]] && [[ ! $ver =~ alpha ]]; then
    LATEST="$ver"
    break
  fi
done
echo -n "$LATEST"
}

while getopts ":i:achv" arg; do
  case "${arg}" in
    a)  sudoInstall=true;;
    c)  cwdInstall=true;;
    i)  VERSION=${OPTARG};;
    h)  usage x; exit;;
    v)  displayVer; exit;;
    \?) echo -e "Error - Invalid option: $OPTARG"; usage; exit;;
    :)  echo "Error - $OPTARG requires an argument"; usage; exit 1;;
  esac
done
shift $((OPTIND-1))

# POPULATE VARIABLES NEEDED TO CREATE DOWNLOAD URL AND FILENAME
if [[ -z "$VERSION" ]]; then
  VERSION=$(getLatest)
fi
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "linux" ]]; then
  PROC=$(lscpu 2> /dev/null | awk '/Architecture/ {if($2 == "x86_64") {print "amd64"; exit} else if($2 ~ /arm/) {print "arm"; exit} else if($2 ~ /aarch64/) {print "arm"; exit} else {print "386"; exit}}')
  if [[ -z $PROC ]]; then
    PROC=$(cat /proc/cpuinfo | awk '/model\ name/ {if($0 ~ /ARM/) {print "arm"; exit}}')
  fi
  if [[ -z $PROC ]]; then
    PROC=$(cat /proc/cpuinfo | awk '/flags/ {if($0 ~ /lm/) {print "amd64"; exit} else {print "386"; exit}}')
  fi
else
  PROC="amd64"
fi
[[ $PROC =~ arm ]] && PROC="arm"  # terraform downloads use "arm" not full arm type

# CREATE FILENAME AND URL FROM GATHERED PARAMETERS
FILENAME="terraform_${VERSION}_${OS}_${PROC}.zip"
LINK="https://releases.hashicorp.com/terraform/${VERSION}/${FILENAME}"
SHALINK="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_SHA256SUMS"

# TEST CALCULATED LINKS
case "${nettool}" in
  wget*)
    LINKVALID=$(wget --spider -S "$LINK" 2>&1 | grep "HTTP/" | awk '{print $2}')
    SHALINKVALID=$(wget --spider -S "$SHALINK" 2>&1 | grep "HTTP/" | awk '{print $2}')
    ;;
  curl*)
    LINKVALID=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$LINK")
    SHALINKVALID=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$SHALINK")
    ;;
esac

# VERIFY LINK VALIDITY
if [[ "$LINKVALID" != 200 ]]; then
  echo -e "Cannot Install - Download URL Invalid"
  echo -e "\nParameters:"
  echo -e "\tVER:\t$VERSION"
  echo -e "\tOS:\t$OS"
  echo -e "\tPROC:\t$PROC"
  echo -e "\tURL:\t$LINK"
  exit 1
fi

# VERIFY SHA LINK VALIDITY
if [[ "$SHALINKVALID" != 200 ]]; then
  echo -e "Cannot Install - URL for Checksum File Invalid"
  echo -e "\tURL:\t$SHALINK"
  exit 1
fi

# DETERMINE DESTINATION
if [[ "$cwdInstall" ]]; then
  BINDIR=$(pwd)
elif [[ -n "$TF_INSTALL_DIR" ]]; then
  BINDIR="$TF_INSTALL_DIR"
  CMDPREFIX="${sudoInstall:+sudo }"
  STREAMLINED=true
elif [[ -w "/usr/local/bin" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX=""
  STREAMLINED=true
elif [[ "$sudoInstall" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX="sudo "
  STREAMLINED=true
else
  echo -e "Terraform Installer\n"
  echo "Specify install directory (a,b or c):"
  echo -en "\t(a) '~/bin'    (b) '/usr/local/bin' as root    (c) abort : "
  read -r -n 1 SELECTION
  echo
  if [ "${SELECTION}" == "a" ] || [ "${SELECTION}" == "A" ]; then
    BINDIR="${HOME}/bin"
    CMDPREFIX=""
  elif [ "${SELECTION}" == "b" ] || [ "${SELECTION}" == "B" ]; then
    BINDIR="/usr/local/bin"
    CMDPREFIX="sudo "
  else
    exit 0
  fi
fi

# CREATE TMPDIR FOR EXTRACTION
if [[ ! "$cwdInstall" ]]; then
  TMPDIR=${TMPDIR:-/tmp}
  UTILTMPDIR="terraform_${VERSION}"

  cd "$TMPDIR" || exit 1
  mkdir -p "$UTILTMPDIR"
  cd "$UTILTMPDIR" || exit 1
fi

# DOWNLOAD ZIP AND CHECKSUM FILES
case "${nettool}" in
  wget*)
    wget -q "$LINK" -O "$FILENAME"
    wget -q "$SHALINK" -O SHAFILE
    ;;
  curl*)
    curl -s -o "$FILENAME" "$LINK"
    curl -s -o SHAFILE "$SHALINK"
    ;;
esac

# VERIFY ZIP CHECKSUM
if shasum -h 2&> /dev/null; then
  expected_sha=$(cat SHAFILE | grep "$FILENAME" | awk '{print $1}')
  download_sha=$(shasum -a 256 "$FILENAME" | cut -d' ' -f1)
  if [ $expected_sha != $download_sha ]; then
    echo "Download Checksum Incorrect"
    echo "Expected: $expected_sha"
    echo "Actual: $download_sha"
    exit 1
  fi
fi

# EXTRACT ZIP
unzip -qq "$FILENAME" || exit 1

# COPY TO DESTINATION
if [[ ! "$cwdInstall" ]]; then
  mkdir -p "${BINDIR}" || exit 1
  ${CMDPREFIX} mv terraform "$BINDIR" || exit 1
  # CLEANUP AND EXIT
  cd "${TMPDIR}" || exit 1
  rm -rf "${UTILTMPDIR}"
  [[ ! "$STREAMLINED" ]] && echo
  echo "Terraform Version ${VERSION} installed to ${BINDIR}"
else
  rm -f "$FILENAME" SHAFILE
  echo "Terraform Version ${VERSION} downloaded"
fi

# create SSH key-pair
ssh-keygen -t rsa -b 2048 -f ~/.ssh/Keypair -q -P '';

# Create vms and deploy application
tf init;
tf apply -auto-approve;

exit 0
