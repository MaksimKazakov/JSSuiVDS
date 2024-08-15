#!/bin/bash
echo
echo -e "   \e[33m!!! Скрипт должен быть запущен под root !!!\e[0m"
echo
LOG_FILE_NAME=exec-log.txt
echo
TIME_START=$(date)
echo
echo -e "\e[33mДата и время создания журнала установки $(date)\e[0m" > ${LOG_FILE_NAME}
echo -e  "\e[33mЖурнал создан ${LOG_FILE_NAME}\e[0m"
echo
# Получение IP адреса машины
IP_ADDRESS=$(curl -s https://ipv4.icanhazip.com/)
echo -e "\e[32m$(date) IP данной машины ${IP_ADDRESS}\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
# Создание нового пользователя
echo -e "\e[33mСоздадим нового пользователя\e[0m"
echo
sleep 1
read -p "$(echo -e "\e[33mВведите нового пользователя: \e[0m")" NEW_USER

useradd -m -g users ${NEW_USER}
echo -e "\e[32m$(date) Новый пользователь ${NEW_USER}\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
# Добавление нового пользователя в sudoers
echo -e "\e[33mДобавление ${NEW_USER} в sudoers\e[0m"
usermod -aG sudo ${NEW_USER}
echo -e "\e[32m$(date) Добавлен ${NEW_USER} в sudoers\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
# Установка пароля для нового пользователя
while true; do
    read -s -p "$(echo -e "\e[33mСоздайте пароль для пользователя ${NEW_USER}: \e[0m")" NEW_USER_PASS
    echo
    read -s -p "$(echo -е "\e[33mПовторите пароль: \е[0м")" NEW_USER_PASS_CONFIRM
    echo
    if [ "$NEW_USER_PASS" == "$NEW_USER_PASS_CONFIRM" ]; then
        break
    else
        echo -e "\e[31mПароли не совпадают. Попробуйте еще раз.\e[0m"
    fi
done
echo

# Настройка SSH ключей для нового пользователя
echo -e "\e[33mУстановим ключи ssh для /home/${NEW_USER}\e[0m" |& tee -a ${LOG_FILE_NAME}
cp -a /root/.ssh /home/${NEW_USER}
chown -R ${NEW_USER}:users /home/${NEW_USER}/.ssh
echo -е "\e[32m$(date) Права /home/${NEW_USER}/.ssh обновлены\e[0м" |& tee -a ${LOG_FILE_NAME}

# Установка софта
echo "*************************************************************************"
echo -е "**************   \e[32mУстанови Java, Docker, Selenoid\e[0м   ***********************"
echo "*************************************************************************"
echo
echo -е "\e[33mОбщее обновление\e[0м"
apt update && apt upgrade -y |& tee -a ${LOG_FILE_NAME}

# Установка JDK
echo -е "\e[34$(date) Установка JDK - 17\e[0м" |& tee -a ${LOG_FILE_NAME}
apt install openjdk-17-jdk -y |& tee -a ${LOG_FILE_NAME}
echo "$(date) $(java --version)" |& tee -a ${LOG_FILE_NAME}
echo "Текущая версия Java $(java --version)" |& tee -a ${LOG_FILE_NAME}

cat << EOF >> /etc/environment
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
EOF
source /etc/environment
echo
echo "\e[33m$(date) Проверка JAVA_HOME\e[0m" |& tee -a ${LOG_FILE_NAME}
echo "\e[33m$(date) JAVA_HOME $(echo $JAVA_HOME)\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[33m$(date) Установка docker и запуск\e[0m" |& tee -a ${LOG_FILE_NAME}
curl -sSL https://get.docker.com | sh
docker version >> ${LOG_FILE_NAME}
usermod -aG docker ${NEW_USER}
echo
echo "\e[33m$(date) Установка docker compose как docker plug-in\e[0m" |& tee -a ${LOG_FILE_NAME}
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
echo
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
docker compose version
echo -e "\e[32m$(date) Версия Docker Compose: $(docker-compose --version)\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
# Копирование тестовой среды
cp -r ./test-bed /home/${NEW_USER} |& tee -a ${LOG_FILE_NAME}
chown -R ${NEW_USER}:users /home/${NEW_USER}/test-bed |& tee -a ${LOG_FILE_NAME}

# Скачивание Chrome images для Selenoid
echo -е "\e[32mСкачивается chrome images для selenoid\e[0м" |& tee -a ${LOG_FILE_NAME}

CHROME_RELEASES="127 126 125"
for RELEASE in $CHROME_RELEASES
do
    echo "\e[32mУстановка chrome ${RELEASE}.0\e[0м" |& tee -a ${LOG_FILE_NAME}
    docker pull selenoid/vnc:chrome_${RELEASE}.0
done

runuser -l ${NEW_USER} -c 'cd ~/test-bed && docker-compose up -d'

echo -е "\e[32mПодождите 1 минуту.... Идет процесс установки....\e[0м"
sleep 30
clear
echo

JENKINS_PASSWORD=$(docker exec -t test-bed_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword)
echo -е "\e[32mПароль Jenkins при первом запуске: ${JENKINS_PASSWORD}\e[0м" |& tee -a ${LOG_FILE_NAME}

echo -е "\e[32mSelenoid's статус: $(curl $IP_ADDRESS:4444/wd/hub/status)\e[0м"|& tee -a ${LOG_FILE_NAME}
echo -е "\e[32mSelenoid's UI статус: $(curl $IP_ADDRESS:8080/status)\e[0м"|& tee -а ${LOG_FILE_NAME}
echo
echo
echo -е "\e[32mТеперь можно проверить Jenkins на: http://$IP_ADDRESS:8888 с паролем $JENKINS_PASSWORD\e[0м"
echo
echo
TIME_END=$(date)
echo "*************************************************************************"
echo "****************   Продолжим настройку стенда   *************************"
echo "*************************************************************************"
echo
echo -е "\e[32mНастроим Jenkins\e[0м"
echo -е "\e[32m1. Остановка контейнеров docker-compose\e[0м" |& tee -а ${LOG_FILE_NAME}
echo
echo
# Перейти в директорию с docker-compose.yml
cd /home/${NEW_USER}/test-bed

docker-compose stop |& tee -а ${LOG_FILE_NAME}

echo -е "\e[32m2. Проверка состояния контейнеров после остановки:\e[0м" |& tee -а ${LOG_FILE_NAME}
echo
echo
docker ps -a |& tee -а ${LOG_FILE_NAME}

if [ "$(docker ps -q)" == ""; then
    echo -е "\e[32mВсе контейнеры успешно остановлены.\e[0м" |& tee -а ${LOG_FILE_NAME}
else
    echo -е "Некоторые контейнеры все еще работают:\e[0м" |& tee -а ${LOG_FILE_NAME}
    docker ps |& tee -а ${LOG_FILE_NAME}
fi

echo -е "\e[32m3. Войти под ${NEW_USER} с паролем ${NEW_USER_PASS} в директорию /home/${NEW_USER}/test-bed\e[0м"
echo
echo
echo -е "\e[32m4. Выполнить команду 'docker compose up -d'\e[0м"
echo
echo

echo "*************************************************************************"
echo "*****************         Что сделано           *************************"
echo "*************************************************************************"

echo -е "\e[32mСоздан новый пользователь '${NEW_USER}' с паролем '${NEW_USER_PASS}'\e[0м"
echo -е "\e[32mФайлы в: /home/$NEW_USER/test-bed\e[0м" |& tee -а ${LOG_FILE_NAME}

echo -е "\e[32mJenkins на адресе ${IP_ADDRESS}:8888\e[0м" |& tee -а ${LOG_FILE_NAME}
echo -е "\e[32mSelenoid на адресе ${IP_ADDRESS}:4444/wd/hub\e[0м" |& tee -а ${LOG_FILE_NAME}
echo -е "\e[32mSelenoid-UI на адресе ${IP_ADDRESS}:8080\e[0м" |& tee -а ${LOG_FILE_NAME}

echo -е "\e[32mВсе логи в файле '${LOG_FILE_NAME}'\e[0м"

echo -е "\e[32mВойдите под '${NEW_USER}' с паролем '${NEW_USER_PASS}' или ssh ${NEW_USER}@${IP_ADDRESS}\e[0м"

echo "Запустился скрипт: $TIME_START" |& tee -а ${LOG_FILE_NAME}
echo "Конец выполнения скрипта: $TIME_END" |& tee -а ${LOG_FILE_NAME}
