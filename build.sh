#!/bin/bash

echo "Скрипт запускать под рутом"
LOG_FILE_NAME=exec-log.txt
TIME_START=$(date)


echo "Дата и время создания создания журнала установки$(date)" > ${LOG_FILE_NAME}
echo "Журнал создан ${LOG_FILE_NAME}"

IP_ADDRESS=$(curl https://ipv4.icanhazip.com/)
echo "$(date) IP address of this machine ${IP_ADDRESS}" |& tee -a ${LOG_FILE_NAME}

echo "Создадим нового пользователя"
sleep 3

read -p "Введите нового пользователя: " NEW_USER

useradd -m -g users ${NEW_USER}
echo "$(date) Новый пользователь ${NEW_USER}" |& tee -a ${LOG_FILE_NAME}

echo "Добавление ${NEW_USER} в sudoers"
usermod -aG sudo ${NEW_USER}

echo "$(date) Добавлени ${NEW_USER} в sudoers" |& tee -a ${LOG_FILE_NAME}

read -p "Создайте пароль для пользователя ${NEW_USER}: " NEW_USER_PASS

echo -e "${NEW_USER_PASS}\n${NEW_USER_PASS}\n" | passwd ${NEW_USER}

echo "$(date) Новый пароль для ${NEW_USER} создан:  ${NEW_USER_PASS} " |& tee -a ${LOG_FILE_NAME}

echo "Установим /home directory" |& tee -a ${LOG_FILE_NAME}
ls /home/ |& tee -a ${LOG_FILE_NAME}

echo "Установим ключи ssh /home/${NEW_USER})"
cp -a /root/.ssh /home/${NEW_USER}

echo "$(date) $(ls -a /home/${NEW_USER}/.ssh) добавлени из root" |& tee -a ${LOG_FILE_NAME}

echo "$(date) Текущий $(ls -lr /home/${NEW_USER}/.ssh)" |& tee -a ${LOG_FILE_NAME}

echo "$(date) Обновление прав /home/${NEW_USER}/.ssh" |& tee -a ${LOG_FILE_NAME}

chown -R ${NEW_USER}:users /home/${NEW_USER}/.ssh

echo "$(date) Права $(ls -a /home/${NEW_USER}/.ssh) обновлены" |& tee -a ${LOG_FILE_NAME}

# установка софта

echo "Общее обновление"
apt update && apt upgrade -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка Midnight Commander"

apt install mc -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка JDK - 17" |& tee -a ${LOG_FILE_NAME}

apt install openjdk-17-jdk -y |& tee -a ${LOG_FILE_NAME}

echo "$(date) $(java --version)" |& tee -a ${LOG_FILE_NAME}

echo "Текущая версия Java $(java --version)" |& tee -a ${LOG_FILE_NAME}

cat << EOF >> /etc/environment
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
EOF

source /etc/environment

echo "$(date) Проверка JAVA_HOME " |& tee -a ${LOG_FILE_NAME}
echo "$(date) JAVA_HOME $(echo $JAVA_HOME)" |& tee -a ${LOG_FILE_NAME}

echo "$(date) Установка docker и запуск" |& tee -a ${LOG_FILE_NAME}

curl -sSL https://get.docker.com | sh

docker version >> ${LOG_FILE_NAME}

usermod -aG docker ${NEW_USER}

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

cp -r ./test-bed /home/${NEW_USER} |& tee -a ${LOG_FILE_NAME}

chown -R ${NEW_USER}:users /home/${NEW_USER}/test-bed |& tee -a ${LOG_FILE_NAME}

# Скачивание Хромов

echo "Скачивается chrome images для selenoid" |& tee -a ${LOG_FILE_NAME}

CHROME_RELEASES="127 126 125"

for RELEASE in $CHROME_RELEASES
do
    echo "Установка chrome ${RELEASE}.0" |& tee -a ${LOG_FILE_NAME}
    docker pull selenoid/vnc:chrome_${RELEASE}.0
done

runuser -l ${NEW_USER} -c 'cd ~/test-bed && docker-compose up -d'

echo "Подождите 1 минуту"

sleep 60

clear

JENKINS_PASSWORD=$(docker exec -t test-bed_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword)

echo "Пароль Jenkins при первом запуске: ${JENKINS_PASSWORD}" |& tee -a ${LOG_FILE_NAME}
echo
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
echo "*************************************************************************"
echo "*****************       QA стенд готов          *************************"
echo "*************************************************************************"

echo "Теперь нужно настроить Jenkins"
echo "1. Остановка контейнеров docker-compose" |& tee -a ${LOG_FILE_NAME}
docker-compose stop |& tee -a ${LOG_FILE_NAME}

echo "2. Проверка состояния контейнеров после остановки:" |& tee -a ${LOG_FILE_NAME}
docker ps -a |& tee -a ${LOG_FILE_NAME}

if [ "$(docker ps -q)" == "" ]; then
    echo "Все контейнеры успешно остановлены." |& tee -a ${LOG_FILE_NAME}
else
    echo "Некоторые контейнеры все еще работают:" |& tee -a ${LOG_FILE_NAME}
    docker ps |& tee -a ${LOG_FILE_NAME}
fi

echo "3. Войти под ${NEW_USER} с паролем ${NEW_USER_PASSWORD}"
echo "4. Выполнить команду "docker-compose up -d command""

echo "*************************************************************************"
echo "*****************         Что сделано           *************************"
echo "*************************************************************************"

echo "Создан новый пользователь'${NEW_USER}' с паролем '${NEW_USER_PASS}'"
echo "Файлы в : /home/$NEW_USER/test-bed" |& tee -a ${LOG_FILE_NAME}

echo "jenkins на адресе ${IP_ADDRESS}:8888" |& tee -a ${LOG_FILE_NAME}
echo "selenoid на адресе ${IP_ADDRESS}:4444/wd/hub" |& tee -a ${LOG_FILE_NAME}
echo "selenoid-ui на адресе ${IP_ADDRESS}:8080" |& tee -a ${LOG_FILE_NAME}

echo "Все логи в файле '${LOG_FILE_NAME}'"

echo "Войдите под '${NEW_USER}' с паролем'${NEW_USER_PASS}' или ssh ${NEW_USER}@${IP_ADDRESS}"


echo "Запустился скрипт:  $TIME_START" |& tee -a ${LOG_FILE_NAME}
echo "Конец выполнения скрипта: $TIME_END" |& tee -a ${LOG_FILE_NAME}