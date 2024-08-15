#!/bin/bash

echo "\e[33mСкрипт запускать под рутом\e[0m"
LOG_FILE_NAME=exec-log.txt
TIME_START=$(date)

echo "\e[33mДата и время создания журнала установки $(date)\e[0m" > ${LOG_FILE_NAME}
echo "\e[33mЖурнал создан ${LOG_FILE_NAME}\e[0m"

# Получение IP адреса машины
IP_ADDRESS=$(curl -s https://ipv4.icanhazip.com/)
echo "\e[32m$(date) IP данной машины ${IP_ADDRESS}\e[0m" |& tee -a ${LOG_FILE_NAME}

# Создание нового пользователя
echo "\e[33mСоздадим нового пользователя\e[0m"
sleep 3
read -p "\e[33mВведите нового пользователя: \e[0m" NEW_USER

useradd -m -g users ${NEW_USER}
echo "\e[32m$(date) Новый пользователь ${NEW_USER}\e[0m" |& tee -a ${LOG_FILE_NAME}

# Добавление нового пользователя в sudoers
echo "\e[33mДобавление ${NEW_USER} в sudoers\e[0m"
usermod -aG sudo ${NEW_USER}
echo "\e[32m$(date) Добавлен ${NEW_USER} в sudoers\e[0m" |& tee -a ${LOG_FILE_NAME}

# Установка пароля для нового пользователя
read -p "\e[33mСоздайте пароль для пользователя ${NEW_USER}: \e[0m" NEW_USER_PASS
echo -e "${NEW_USER_PASS}\n${NEW_USER_PASS}\n" | passwd ${NEW_USER}
echo "\e[32m$(date) Новый пароль для ${NEW_USER} создан\e[0m" |& tee -a ${LOG_FILE_NAME}

# Настройка SSH ключей для нового пользователя
echo "\e[33mУстановим ключи ssh для /home/${NEW_USER}\e[0m" |& tee -a ${LOG_FILE_NAME}
cp -a /root/.ssh /home/${NEW_USER}
chown -R ${NEW_USER}:users /home/${NEW_USER}/.ssh
echo "\e[32m$(date) Права /home/${NEW_USER}/.ssh обновлены\e[0m" |& tee -a ${LOG_FILE_NAME}

# Проверка наличия Java
echo "\e[33mПроверка установки Java...\e[0m" |& tee -a ${LOG_FILE_NAME}
if java -version &> /dev/null; then
    CURRENT_JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "\e[32mОбнаружена установленная версия Java: ${CURRENT_JAVA_VERSION}\e[0m" |& tee -a ${LOG_FILE_NAME}
    read -p "\e[33mХотите установить Java 11 и сделать её JAVA_HOME? [y/n]: \e[0m" INSTALL_JAVA
else
    echo "\e[31mJava не установлена.\e[0m" |& tee -a ${LOG_FILE_NAME}
    INSTALL_JAVA="y"
fi

# Установка Java 11
if [ "$INSTALL_JAVA" == "y" ]; then
    echo "\e[33m$(date) Установка JDK 11\e[0m" |& tee -a ${LOG_FILE_NAME}
    apt install openjdk-11-jdk -y |& tee -a ${LOG_FILE_NAME}
    echo "\e[32mТекущая версия Java $(java --version)\e[0m" |& tee -a ${LOG_FILE_NAME}

    # Установка JAVA_HOME в системе
    cat << EOF >> /etc/environment
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
EOF
    source /etc/environment
    echo "\e[32m$(date) JAVA_HOME установлен в систему: $JAVA_HOME\e[0m" |& tee -a ${LOG_FILE_NAME}
else
    echo "\e[31mJava 11 не была установлена.\e[0m" |& tee -a ${LOG_FILE_NAME}
fi

# Проверка наличия Docker
echo "\e[33mПроверка установки Docker...\e[0m" |& tee -a ${LOG_FILE_NAME}
if docker --version &> /dev/null; then
    echo "\e[32mDocker уже установлен: $(docker --version)\e[0m" |& tee -a ${LOG_FILE_NAME}
else
    echo "\e[33m$(date) Установка Docker и запуск\e[0m" |& tee -a ${LOG_FILE_NAME}
    curl -sSL https://get.docker.com | sh |& tee -a ${LOG_FILE_NAME}
    docker version |& tee -a ${LOG_FILE_NAME}
    usermod -aG docker ${NEW_USER}
fi

# Проверка наличия Docker Compose
echo "\e[33mПроверка установки Docker Compose...\e[0m" |& tee -a ${LOG_FILE_NAME}
if docker-compose --version &> /dev/null; then
    echo "\e[32mDocker Compose уже установлен: $(docker-compose --version)\e[0m" |& tee -a ${LOG_FILE_NAME}
else
    echo "\e[33m$(date) Установка Docker Compose\e[0m" |& tee -a ${LOG_FILE_NAME}
    apt-get install docker-compose -y |& tee -a ${LOG_FILE_NAME}
    echo "\e[32m$(date) Версия Docker Compose: $(docker-compose --version)\e[0m" |& tee -a ${LOG_FILE_NAME}
fi

# Копирование тестовой среды
cp -r ./test-bed /home/${NEW_USER} |& tee -a ${LOG_FILE_NAME}
chown -R ${NEW_USER}:users /home/${NEW_USER}/test-bed |& tee -a ${LOG_FILE_NAME}

# Скачивание Chrome images для Selenoid
echo "\e[33mСкачивание Chrome images для Selenoid\e[0m" |& tee -a ${LOG_FILE_NAME}
CHROME_RELEASES="127 126 125"
for RELEASE in $CHROME_RELEASES
do
    echo "\e[33mУстановка Chrome ${RELEASE}.0\e[0m" |& tee -a ${LOG_FILE_NAME}
    docker pull selenoid/vnc:chrome_${RELEASE}.0 |& tee -a ${LOG_FILE_NAME}
done

# Запуск Docker Compose
runuser -l ${NEW_USER} -c 'cd ~/test-bed && docker-compose up -d' |& tee -a ${LOG_FILE_NAME}

# Подождать, чтобы контейнеры запустились
echo "\e[33mПодождите 1 минуту, чтобы контейнеры запустились\e[0m" |& tee -a ${LOG_FILE_NAME}
sleep 60
clear

# Установка Java 11 в контейнер Jenkins
JENKINS_CONTAINER=$(docker ps --filter "ancestor=jenkins/jenkins:lts" --format "{{.ID}}")

echo "\e[33m$(date) Установка Java 11 в контейнер Jenkins\e[0m" |& tee -a ${LOG_FILE_NAME}
docker exec -u root $JENKINS_CONTAINER bash -c 'curl -LO https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz && tar -xzf openjdk-11.0.2_linux-x64_bin.tar.gz -C /opt && rm openjdk-11.0.2_linux-x64_bin.tar.gz' |& tee -a ${LOG_FILE_NAME}

docker exec -u root $JENKINS_CONTAINER bash -c 'echo "export JAVA_HOME=/opt/jdk-11.0.2" >> /etc/profile && echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile' |& tee -a ${LOG_FILE_NAME}
docker exec -u root $JENKINS_CONTAINER bash -c 'source /etc/profile && echo "JAVA_HOME установлен: \$JAVA_HOME"' |& tee -a ${LOG_FILE_NAME}

# Получение пароля Jenkins и проверка статуса Selenoid
echo
echo
JENKINS_PASSWORD=$(docker exec -t $JENKINS_CONTAINER cat /var/jenkins_home/secrets/initialAdminPassword)
echo "*******************************************************************************"
echo "*************   \e[32mПароль Jenkins при первом запуске\e[0m   ***************************"
echo "*******************************************************************************"
echo
echo
echo "\e[32mПароль Jenkins при первом запуске: ${JENKINS_PASSWORD}\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[32mSelenoid статус: $(curl -s $IP_ADDRESS:4444/wd/hub/status)\e[0m" |& tee -a ${LOG_FILE_NAME}
echo "\e[32mSelenoid UI статус: $(curl -s $IP_ADDRESS:8080/status)\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[32mТеперь можно проверить Jenkins на: http://$IP_ADDRESS:8888 с паролем $JENKINS_PASSWORD\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
# Остановка контейнеров
echo "\e[33mОстановка контейнеров, установленных по этому скрипту...\e[0m" |& tee -a ${LOG_FILE_NAME}
docker-compose -f /home/${NEW_USER}/test-bed/docker-compose.yml down |& tee -a ${LOG_FILE_NAME}
echo
# Проверка оставшихся запущенных контейнеров
RUNNING_CONTAINERS=$(docker ps -q)
if [ -z "$RUNNING_CONTAINERS" ]; then
    echo "\e[32mВсе контейнеры, установленные по этому скрипту, успешно остановлены.\e[0m" |& tee -a ${LOG_FILE_NAME}
else
    echo "\e[31mНекоторые контейнеры все еще работают:\e[0m" |& tee -a ${LOG_FILE_NAME}
    docker ps |& tee -a ${LOG_FILE_NAME}
fi
echo
# Итоги работы скрипта
TIME_END=$(date)
echo "*************************************************************************"
echo "****************   \e[32mПродолжим настройку стенда\e[0m   *************************"
echo "*************************************************************************"
echo
echo
echo "\e[32mСоздан новый пользователь '${NEW_USER}' с паролем '${NEW_USER_PASS}'\e[0m"
echo
echo "\e[32mФайлы в: /home/$NEW_USER/test-bed\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[32mJenkins на адресе ${IP_ADDRESS}:8888\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[32mSelenoid на адресе ${IP_ADDRESS}:4444/wd/hub\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[32mSelenoid-UI на адресе ${IP_ADDRESS}:8080\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[32mВсе логи в файле '${LOG_FILE_NAME}'\e[0m"
echo
echo "\e[32mЗапустился скрипт: $TIME_START\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
echo "\e[32mКонец выполнения скрипта: $TIME_END\e[0m" |& tee -a ${LOG_FILE_NAME}
echo
