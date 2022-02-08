#!/bin/bash
function docker_ce_install() {
    echo "update env. "
    yum update -y
    yum install -y yum-utils
    yum install -y git
    yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

    echo "you can use below command, if you need to choice the newest docker-ce version"
    echo "yum list docker-ce --showduplicates | sort -r"
    echo "example :"
    echo "
    docker-ce.x86_64            3:20.10.7-3.el7                    docker-ce-stable
    docker-ce.x86_64            3:20.10.6-3.el7                    docker-ce-stable
    docker-ce.x86_64            3:19.03.9-3.el7                    docker-ce-stable
    docker-ce.x86_64            3:19.03.8-3.el7                    docker-ce-stable
    docker-ce.x86_64            3:18.09.9-3.el7                    docker-ce-stable
    docker-ce.x86_64            3:18.09.8-3.el7                    docker-ce-stable
    "
    echo "choice [x86_64, 3:**, docker-ce-stable] ..."
    echo "3:20.10.7-3.el7 --> version 20.10.7"
    echo ""
    echo "Here will wait 5 sec. for repentance."
    sleep 5

    echo "install docker ce ... we choice 20.10.7 (might be updated by system.)"
    yum install -y docker-ce-20.10.7 docker-ce-cli-20.10.7 containerd.io
    sleep 1
    
    _NEEDTOSETCONF="FALSE"
    if [ ! -e "/etc/docker" ]; then
        mkdir -p /etc/docker
        _NEEDTOSETCONF="TRUE"
    elif [ ! -e "/etc/docker/daemon.json" ]; then
        _NEEDTOSETCONF="TRUE"
    else
        echo "already add daemon.json"
    fi

    if [ "$_NEEDTOSETCONF" == "TRUE" ]; then
cat << EOF > /etc/docker/daemon.json
{
 "log-driver": "json-file",
 "log-opts": {
   "max-size": "50m",
   "max-file": "3"
 }
}
EOF
        
    fi
    cat /etc/docker/daemon.json

    echo ""
    echo "update to the newest docker-ce version"
    yum update -y
    docker version
    echo ""

    sleep 2
    systemctl start docker
    systemctl enable docker
}

function docker_old_remove() {
    echo "stop & remove running docker container ..."
    docker stop $(sudo docker ps -a -q)
    docker rm $(sudo docker ps -a -q)
    sleep 1
    service stop docker
    sleep 1
    echo "uninstall old version ... "
    yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
    
}

function docker_ce_remove() {
    echo "uninstall docker ce ... ?"
    yum remove -y docker-ce-18.09.1 docker-ce-cli-18.09.1 containerd.io
    if [ $? -eq 1 ]; then
        echo "fail to remove docker-ce 18.09.1 ... just remove default choice tag ..."
        yum remove -y docker-ce docker-ce-cli containerd.io
    fi
}

function docker_menu_install() {
    echo "install docker system ... "
    echo -n "your current docker server/client version is:"
    docker version 2>&1 3>&1
    if [ $? -gt 0 ]; then
        echo "system cannot find any running docker server! Did it not been installed or service not running?"
        echo "install docker ce ... "
        docker_ce_install
    else
        echo "Our company recommends using more than version 20.x.x "
        read -p "Do you accept to install docker server (20.10.7)? yes, re-install or No! (y/r/N): " answer
        if [ "$answer" == 'y' ] || [ "$answer" == 'Y' ]; then
            docker_old_remove
            sync 
            sleep 1
            docker_ce_install
        elif [ "$answer" == 'r' ] || [ "$answer" == 'R' ]; then
            docker_ce_remove
            sync 
            sleep 1
            docker_ce_install
        else
            echo "deny ..."
        fi
    fi
}

function docker_compose_install() {
    echo "install docker-compose ... if it's not exist we will try to install v1.29.2 "
    echo "(depend on https://docs.docker.com/compose/install/)"
    if [ -e "/usr/local/bin/docker-compose" ]; then
        echo "docker_compose already installed ...  "
        docker-compose --version
        whereis docker-compose
        echo ""
    else
        echo "use the info. at 2022/02/08"
        curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        docker-compose --version
        whereis docker-compose
        echo ""
    fi
    echo ""
}

function adddir() {
    echo "check folder exist or not?"
    if [ ! -e ./nginx ]; then
        mkdir nginx
    fi
    if [ ! -e ./php ]; then
        mkdir php
    fi
    if [ ! -e ./database ]; then
        mkdir database
    fi
    if [ ! -e ./projects ]; then
        mkdir projects
    fi
    echo ""
}

function changeconf() {
    echo "chang conf."
    _ChangeConf="FALSE"
    read -p "Do you need to change configuration? (y/N:default): " answer
    if [ "$answer" == 'y' ] || [ "$answer" == 'Y' ]; then
        _ChangeConf="TRUE"
    else
        echo "use default ..."
    fi

    if [ "$_ChangeConf" == "TRUE" ]; then
        echo "about nginx:"
        _NGINX_SERVER=`cat ./nginx/conf.d/laravel.conf | grep 'server_name'`
        echo "> $_NGINX_SERVER"

        read -p "What server name you want to replace ...: " server_name
        sed -i "s/server_name.*/server_name $server_name;/g" nginx/conf.d/laravel.conf
    fi
    echo ""
}

function main() {
    echo "install docker ce:"
    _STARTT=`date "+%s"`
    docker_menu_install
    docker_compose_install
    _ENDT=`date "+%s"`
    _SPENDT=$(($_ENDT - $_STARTT))
    echo "using $_SPENDT second."
    echo "=============================="
    echo "you can use 'sudo yum update -y' to update the docker service version"
    echo ""

    echo "install and start projects"
    adddir
    changeconf

}

main
