#!/bin/bash

LOG_FILE_NAME=uninstall-log.txt
TIME_START=$(date)

echo "Дата и время начала удаления $(date)" > ${LOG_FILE_NAME}
echo "Журнал удаления создан ${LOG_FILE_NAME}"

# Получение IP адреса машины
IP_ADDRESS=$(curl -s https://ipv4.icanhazip.com/)
echo "$(date) IP address of this machine ${IP_ADDRESS}" |& tee -a ${LOG_FILE_NAME}

# Удаление пользователя
read -p "Введите имя пользователя, которого хотите удалить: " NEW_USER
if id "$NEW_USER" &>/dev/null; then
    echo "Удаление пользователя ${NEW_USER}..."
    userdel -r ${NEW_USER}
    echo "$(date) Пользователь ${NEW_USER} удален." |& tee -a ${LOG_FILE_NAME}
else
    echo "Пользователь ${NEW_USER} не найден." |& tee -a ${LOG_FILE_NAME}
fi

# Удаление Docker и Docker Compose
echo "Удаление Docker и Docker Compose..."
if dpkg -l | grep -q docker; then
    apt-get purge -y docker docker-engine docker.io containerd runc |& tee -a ${LOG_FILE_NAME}
    echo "$(date) Docker удален." |& tee -a ${LOG_FILE_NAME}
else
    echo "Docker не установлен." |& tee -a ${LOG_FILE_NAME}
fi

if dpkg -l | grep -q docker-compose; then
    apt-get purge -y docker-compose |& tee -a ${LOG_FILE_NAME}
    echo "$(date) Docker Compose удален." |& tee -a ${LOG_FILE_NAME}
else
    echo "Docker Compose не установлен." |& tee -a ${LOG_FILE_NAME}
fi

# Удаление JDK
echo "Удаление Java..."
if dpkg -l | grep -q openjdk-11-jdk; then
    apt-get purge -y openjdk-11-jdk |& tee -a ${LOG_FILE_NAME}
    echo "$(date) Java 11 удалена." |& tee -a ${LOG_FILE_NAME}
else
    echo "Java 11 не установлена." |& tee -a ${LOG_FILE_NAME}
fi

# Удаление директории с тестовой средой
TEST_BED_DIR="/home/${NEW_USER}/test-bed"
if [ -d "$TEST_BED_DIR" ]; then
    echo "Удаление директории ${TEST_BED_DIR}..."
    rm -rf ${TEST_BED_DIR}
    echo "$(date) Директория ${TEST_BED_DIR} удалена." |& tee -a ${LOG_FILE_NAME}
else
    echo "Директория ${TEST_BED_DIR} не найдена." |& tee -a ${LOG_FILE_NAME}
fi

# Очистка системы
echo "Очистка системы от ненужных пакетов..."
apt-get autoremove -y |& tee -a ${LOG_FILE_NAME}
apt-get clean |& tee -a ${LOG_FILE_NAME}

# Итоги работы скрипта
TIME_END=$(date)
echo "*************************************************************************"
echo "*******************   \e[32mУдаление завершено\e[0m   ****************************"
echo "*************************************************************************"
echo "Начало удаления: $TIME_START" |& tee -a ${LOG_FILE_NAME}
echo "Конец удаления: $TIME_END" |& tee -a ${LOG_FILE_NAME}
