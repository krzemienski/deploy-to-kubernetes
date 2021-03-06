#!/bin/bash

# use the bash_colors.sh file
found_colors="./tools/bash_colors.sh"
if [[ "${DISABLE_COLORS}" == "" ]] && [[ "${found_colors}" != "" ]] && [[ -e ${found_colors} ]]; then
    . ${found_colors}
else
    inf() {
        echo "$@"
    }
    anmt() {
        echo "$@"
    }
    good() {
        echo "$@"
    }
    err() {
        echo "$@"
    }
    critical() {
        echo "$@"
    }
    warn() {
        echo "$@"
    }
fi

user_test=$(whoami)
if [[ "${user_test}" != "root" ]]; then
	err "please run as root"
	exit 1
fi

restart_nfs=0
project_dir=/data/k8

install_check=$(dpkg -l | grep nfs-common | wc -l)
if [[ "${install_check}" == "0" ]]; then
	inf "installing nfs-common"
	apt-get install nfs-common
	restart_nfs=1
fi
install_check=$(dpkg -l | grep nfs-kernel-server | wc -l)
if [[ "${install_check}" == "0" ]]; then
	inf "installing nfs-kernel-server"
	apt-get install nfs-kernel-server
	restart_nfs=1
fi

if [[ ! -e ${project_dir}/postgres ]]; then
	mkdir -p -m 777 ${project_dir}/postgres
	inf "installing nfs mounts: postgres"
	chown nobody:nogroup ${project_dir}/postgres
	restart_nfs=1
fi

if [[ ! -e ${project_dir}/pgadmin ]]; then
	inf "installing nfs mounts: pgadmin"
	mkdir -p -m 777 ${project_dir}/pgadmin
	chown nobody:nogroup ${project_dir}/pgadmin
	restart_nfs=1
fi

if [[ ! -e ${project_dir}/redis ]]; then
	inf "installing nfs mounts: redis"
	mkdir -p -m 777 ${project_dir}/redis
	chown nobody:nogroup ${project_dir}/redis
	restart_nfs=1
fi

test_pgadmin_nfs=$(cat /etc/exports | grep k8 | grep pgadmin | grep 10.0.0.0 | wc -l)
if [[ "${test_pgadmin_nfs}" == "0" ]]; then
    inf "installing 10.0.0.0 nfs mounts for pgadmin"
    echo '/data/k8/pgadmin 10.0.0.0/24(rw,sync,no_subtree_check)' >> /etc/exports
	restart_nfs=1
fi
test_pgadmin_nfs=$(cat /etc/exports | grep k8 | grep pgadmin | grep localhost | wc -l)
if [[ "${test_pgadmin_nfs}" == "0" ]]; then
    inf "installing localhost nfs mounts for pgadmin"
    echo '/data/k8/pgadmin localhost(rw,sync,no_subtree_check)' >> /etc/exports
	restart_nfs=1
fi

test_postgres_nfs=$(cat /etc/exports | grep k8 | grep postgres | grep 10.0.0.0 | wc -l)
if [[ "${test_postgres_nfs}" == "0" ]]; then
    inf "installing 10.0.0.0 nfs mounts for postgres"
    echo '/data/k8/postgres 10.0.0.0/24(rw,sync,no_subtree_check)' >> /etc/exports
	restart_nfs=1
fi
test_postgres_nfs=$(cat /etc/exports | grep k8 | grep postgres | grep localhost | wc -l)
if [[ "${test_postgres_nfs}" == "0" ]]; then
    inf "installing localhost nfs mounts for postgres"
    echo '/data/k8/postgres localhost(rw,sync,no_subtree_check)' >> /etc/exports
	restart_nfs=1
fi

test_redis_nfs=$(cat /etc/exports | grep k8 | grep redis | grep 10.0.0.0 | wc -l)
if [[ "${test_redis_nfs}" == "0" ]]; then
    inf "installing 10.0.0.0 nfs mounts for redis"
    echo '/data/k8/redis 10.0.0.0/24(rw,sync,no_subtree_check)' >> /etc/exports
	restart_nfs=1
fi
test_redis_nfs=$(cat /etc/exports | grep k8 | grep redis | grep localhost | wc -l)
if [[ "${test_redis_nfs}" == "0" ]]; then
    inf "installing localhost nfs mounts for redis"
    echo '/data/k8/redis localhost(rw,sync,no_subtree_check)' >> /etc/exports
	restart_nfs=1
fi

if [[ "${restart_nfs}" == "1" ]]; then
	inf "enabling nfs server for reboots"
	systemctl enable nfs-kernel-server
	inf "restarting nfs server"
	systemctl restart nfs-kernel-server
fi

good "done creating persistent volumes"

exit 0
