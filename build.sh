#!/bin/bash

echo "Скрипт запускать под root"

# Создать файл журнала установки
LOG_FILE_NAME=exec-log.txt
# Время старта
TIME_START=$(date)


echo "Файл журнала создан $(date)" > ${LOG_FILE_NAME}
echo "Файл журнала установки ${LOG_FILE_NAME}"

IP_ADDRESS=$(curl https://ipv4.icanhazip.com/)

echo "$(date) IP адрес данного компьютера ${IP_ADDRESS}" |& tee -a ${LOG_FILE_NAME}

# Установка 

echo "Общее обновление"
apt update && apt upgrade -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка Midnight Commander"

apt install mc -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка JDK - 17" |& tee -a ${LOG_FILE_NAME}

apt install openjdk-17-jdk -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) $(java --version)" |& tee -a ${LOG_FILE_NAME}

echo "Текущая версия Java $(java --version)" |& tee -a ${LOG_FILE_NAME}

echo "Обновление JAVA_HOME"

cat << EOF >> /etc/environment
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
EOF

source /etc/environment

echo "$(date) Проверка JAVA_HOME " |& tee -a ${LOG_FILE_NAME}
echo "$(date) JAVA_HOME $(echo $JAVA_HOME)" |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка docker и запуск" |& tee -a ${LOG_FILE_NAME}

curl -sSL https://get.docker.com | sh

docker version >> ${LOG_FILE_NAME}


echo "$(date) Установка docker-compose..." |& tee -a ${LOG_FILE_NAME}
apt-get install docker-compose -y
echo "$(date) Проверка верскии docker-compose" |& tee -a ${LOG_FILE_NAME}
docker-compose version


# echo "$(date) Installing docker compose as docker plug-in..." |& tee -a ${LOG_FILE_NAME}

# DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
# mkdir -p $DOCKER_CONFIG/cli-plugins
# curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

# chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
# sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
# docker compose version

# cp -r ./test-bed /home/${NEW_USER} |& tee -a ${LOG_FILE_NAME}

# chown -R ${NEW_USER}:users /home/${NEW_USER}/test-bed |& tee -a ${LOG_FILE_NAME}

# Pulling chrome images for selenoid

echo "Установка образов selenoid" |& tee -a ${LOG_FILE_NAME}

CHROME_RELEASES="120 121 122"

for RELEASE in $CHROME_RELEASES
do
    echo "Установлена версия браузера -  ${RELEASE}.0" |& tee -a ${LOG_FILE_NAME}
    docker pull selenoid/vnc:chrome_${RELEASE}.0
done

runuser -l -c 'cd ~/test-bed && docker-compose up -d'

echo "Waiting 60 seconds for jenkins to start up."

sleep 60

clear

JENKINS_PASSWORD=$(docker exec -t test-bed_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword)

echo "This is your initial Jenkins admin password: ${JENKINS_PASSWORD}" |& tee -a ${LOG_FILE_NAME}
echo
echo
echo
echo

echo "Selenoid's status: $(curl $IP_ADDRESS:4444/wd/hub/status)"|& tee -a ${LOG_FILE_NAME}

echo
echo
echo
echo "Selenoid's UI status: $(curl $IP_ADDRESS:8080/status)"|& tee -a ${LOG_FILE_NAME}

echo
echo
echo
echo "Now, try to open Jenkins at: http://$IP_ADDRESS:8888 and use $JENKINS_PASSWORD"


TIME_END=$(date)

echo "QA test bed setup has been completed"
echo "Now, you need to configure Jenkins and you are ready to go."
echo "1. Stop your test bed with docker-compose down (you need to be in the folder with the configs to do that)"
echo "2. Log-in as ${NEW_USER} with password ${NEW_USER_PASSWORD}"
echo "3. Start test bed with docker-compose up -d command"

echo "What's done:"
echo "Root's password has been updated to '${ROOT_PASS}'"
echo "New user '${NEW_USER}' has been created with the password '${NEW_USER_PASS}'"
echo "Test bed files are here: /home/$NEW_USER/test-bed" |& tee -a ${LOG_FILE_NAME}
echo "jenkins, selenoid, selenoid-ui docker images were downloaded and started"
echo "jenkins application ${IP_ADDRESS}:8888" |& tee -a ${LOG_FILE_NAME}
echo "selenoid application ${IP_ADDRESS}:4444/wd/hub" |& tee -a ${LOG_FILE_NAME}
echo "selenoid-ui application ${IP_ADDRESS}:8080" |& tee -a ${LOG_FILE_NAME}

echo "All logs of this script are stored in '${LOG_FILE_NAME}', so if you missed something, check the log"

echo "Now, you need to close the connection - 'exit'"
echo "Log in as '${NEW_USER}' with the password '${NEW_USER_PASS}' via ssh ${NEW_USER}@${IP_ADDRESS}"


echo "Started:  $TIME_START" |& tee -a ${LOG_FILE_NAME}
echo "Finished: $TIME_END" |& tee -a ${LOG_FILE_NAME}
