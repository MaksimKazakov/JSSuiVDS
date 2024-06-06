#!/bin/bash

echo "Скрипт запускать под рутом"
LOG_FILE_NAME=exec-log.txt
TIME_START=$(date)

echo "Дата и время создания создания журнала установки: $(date)" > ${LOG_FILE_NAME}
echo "Журнал создан: ${LOG_FILE_NAME}"

IP_ADDRESS=$(curl https://ipv4.icanhazip.com/)
echo "$(date) IP address of this machine: ${IP_ADDRESS}" |& tee -a ${LOG_FILE_NAME}

echo "Установим /home directory" |& tee -a ${LOG_FILE_NAME}
ls /home/ |& tee -a ${LOG_FILE_NAME}

echo "Установим ключи ssh /root/.ssh"
cp -a /root/.ssh /home/root

echo "$(date) $(ls -a /home/root/.ssh) добавлено из root" |& tee -a ${LOG_FILE_NAME}

echo "$(date) Текущее $(ls -lr /home/root/.ssh)" |& tee -a ${LOG_FILE_NAME}

echo "$(date) Обновление прав /home/root/.ssh" |& tee -a ${LOG_FILE_NAME}
chown -R root:root /home/root/.ssh

echo "$(date) Права $(ls -a /home/root/.ssh) обновлены" |& tee -a ${LOG_FILE_NAME}

# установка софта

echo "Общее обновление"
apt update && apt upgrade -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка Midnight Commander"
apt install mc -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка JDK - 21" |& tee -a ${LOG_FILE_NAME}
apt install openjdk-21-jdk -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) $(java --version)" |& tee -a ${LOG_FILE_NAME}
echo "Текущая версия Java $(java --version)" |& tee -a ${LOG_FILE_NAME}

cat << EOF >> /etc/environment
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
EOF

source /etc/environment

echo "$(date) Проверка JAVA_HOME " |& tee -a ${LOG_FILE_NAME}
echo "$(date) JAVA_HOME $(echo $JAVA_HOME)" |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка docker и запуск" |& tee -a ${LOG_FILE_NAME}
curl -sSL https://get.docker.com | sh
docker version >> ${LOG_FILE_NAME}

echo "$(date) Установка docker-compose..." |& tee -a ${LOG_FILE_NAME}
apt-get install docker-compose -y

echo "$(date) Версия docker-compose: " |& tee -a ${LOG_FILE_NAME}
docker-compose version

echo "$(date) Установка docker compose как docker plug-in " |& tee -a ${LOG_FILE_NAME}
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version

cp -r ./test-bed /home/root |& tee -a ${LOG_FILE_NAME}
chown -R root:root /home/root/test-bed |& tee -a ${LOG_FILE_NAME}

# Скачивание Хромов

echo "Скачивается chrome images для selenoid" |& tee -a ${LOG_FILE_NAME}
CHROME_RELEASES="125"

for RELEASE in $CHROME_RELEASES
do
    echo "Установка chrome ${RELEASE}.0" |& tee -a ${LOG_FILE_NAME}
    docker pull selenoid/vnc:chrome_${RELEASE}.0
done

cd /home/root/test-bed && docker-compose up -d

echo "Подождите 1 минуту"
sleep 60
clear

JENKINS_PASSWORD=$(docker exec -t test-bed_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword)

echo "Пароль Jenkins при первом запуске: ${JENKINS_PASSWORD}" |& tee -a ${LOG_FILE_NAME}
echo
echo
echo
echo "Selenoid's статус: $(curl $IP_ADDRESS:4444/wd/hub/status)"|& tee -a ${LOG_FILE_NAME}

echo
echo
echo
echo "Selenoid's UI статус: $(curl $IP_ADDRESS:8080/status)"|& tee -a ${LOG_FILE_NAME}

echo
echo
echo
echo "Теперь можно проверить Jenkins на: http://$IP_ADDRESS:8888 с паролем $JENKINS_PASSWORD"


TIME_END=$(date)

echo "QA стенд готов"
echo "Теперь нужно настроить Jenkins"
echo "1. Остановить docker-compose"
echo "2. Запустить docker-compose снова: cd /home/root/test-bed && docker-compose up -d"
echo "3. Проверить Jenkins на: http://$IP_ADDRESS:8888 с паролем $JENKINS_PASSWORD"

echo "Что сделано:"
echo "Файлы в : /home/root/test-bed" |& tee -a ${LOG_FILE_NAME}
echo "jenkins, selenoid, selenoid-ui docker images запущены"
echo "jenkins на адресе ${IP_ADDRESS}:8888" |& tee -a ${LOG_FILE_NAME}
echo "selenoid на адресе ${IP_ADDRESS}:4444/wd/hub" |& tee -a ${LOG_FILE_NAME}
echo "selenoid-ui на адресе ${IP_ADDRESS}:8080" |& tee -a ${LOG_FILE_NAME}

echo "Все логи в файле '${LOG_FILE_NAME}'"

echo "Запустился скрипт:  $TIME_START" |& tee -a ${LOG_FILE_NAME}
echo "Конец выполнения скрипта: $TIME_END" |& tee -a ${LOG_FILE_NAME}
