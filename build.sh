#!/bin/bash

#use following to update the repo from github
#git fetch && git reset --hard HEAD &&git merge '@{u}'

# deleting a user
# killall -u $1 && userdel -f $1 && userdel -r $1
# userdel -rfRZ $1

echo "Script should be started under root user"

#creating new log file
LOG_FILE_NAME=exec-log.txt
# just out of curiocity< how long will it take
TIME_START=$(date)


echo "$(date) log file has been created" > ${LOG_FILE_NAME}
echo "Log file ${LOG_FILE_NAME} has been created."

IP_ADDRESS=$(curl https://ipv4.icanhazip.com/)

echo "$(date) IP address of this machine ${IP_ADDRESS}" |& tee -a ${LOG_FILE_NAME}

# echo "$(date) IP address of this machine ${IP_ADDRESS}"

# Creating the password for the user root

echo "#########################################################"
echo "We would need to create a new password for you, $(whoami)"
echo "#########################################################"

read -p "Please enter new password for your account: " ROOT_PASS
echo $ROOT_PASS

echo "Created new password for $(whoami) = ${ROOT_PASS}" |& tee -a ${LOG_FILE_NAME}

echo -e "${ROOT_PASS}\n${ROOT_PASS}\n" | passwd

clear

echo "Installing new software..."

# Updating repositories and upgrading installed software
echo "Updating repos, upgrading installed software"
apt update && apt upgrade -y |& tee -a ${LOG_FILE_NAME}

# Installing Midnight Commander
echo "$(date) Installing Midnight Commander"
apt install mc -y |& tee -a ${LOG_FILE_NAME}

# Installing default JDK
echo "$(date) Installing default JDK" |& tee -a ${LOG_FILE_NAME}
apt install default-jdk -y |& tee -a ${LOG_FILE_NAME}

# Checking installed Java version
echo "$(date) $(java --version)" |& tee -a ${LOG_FILE_NAME}
echo "Curent Java version is $(java --version)" |& tee -a ${LOG_FILE_NAME}

# Setting JAVA_HOME environment variable
echo "Updating JAVA_HOME environment variable" |& tee -a ${LOG_FILE_NAME}
cat << EOF >> /etc/environment
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
EOF
source /etc/environment
echo "$(date) Checking JAVA_HOME is set" |& tee -a ${LOG_FILE_NAME}
echo "$(date) echo JAVA_HOME is set to $(echo $JAVA_HOME)" |& tee -a ${LOG_FILE_NAME}

# Installing Docker
echo "$(date) Downloading script for the Docker installation and running it" |& tee -a ${LOG_FILE_NAME}
curl -sSL https://get.docker.com | sh
docker version >> ${LOG_FILE_NAME}

# Installing Docker Compose
echo "$(date) Installing Docker Compose..." |& tee -a ${LOG_FILE_NAME}
apt-get install docker-compose -y
echo "$(date) Checking Docker Compose version" |& tee -a ${LOG_FILE_NAME}
docker-compose version

# Installing Docker Compose as Docker plugin
# echo "$(date) Installing Docker Compose as Docker plugin..." |& tee -a ${LOG_FILE_NAME}
# DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
# mkdir -p $DOCKER_CONFIG/cli-plugins
# curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
# chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
# sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
# docker compose version

# Pulling Chrome images for Selenoid
echo "Pulling Chrome images for Selenoid" |& tee -a ${LOG_FILE_NAME}
CHROME_RELEASES="120 121 122"
for RELEASE in $CHROME_RELEASES
do
    echo "Pulling Chrome ${RELEASE}.0" |& tee -a ${LOG_FILE_NAME}
    docker pull selenoid/vnc:chrome_${RELEASE}.0
done

# Starting the test bed services
echo "Starting test bed services..." |& tee -a ${LOG_FILE_NAME}
cd /home/${NEW_USER}/test-bed && docker-compose up -d

echo "Waiting 60 seconds for Jenkins to start up..." |& tee -a ${LOG_FILE_NAME}
sleep 60


JENKINS_PASSWORD=$(docker exec -t test-bed_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword)

echo "This is your initial Jenkins admin password: ${JENKINS_PASSWORD}" |& tee -a ${LOG_FILE_NAME}
echo "Selenoid's status: $(curl $IP_ADDRESS:4444/wd/hub/status)"|& tee -a ${LOG_FILE_NAME}
echo "Selenoid's UI status: $(curl $IP_ADDRESS:8080/status)"|& tee -a ${LOG_FILE_NAME}
echo "Now, try to open Jenkins at: http://$IP_ADDRESS:8888 and use $JENKINS_PASSWORD"

TIME
