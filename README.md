# Разворачивание VDS
Установим:
1. Java - 17 
2. Jenkins
3. Selenoid
4. Selenoid UI


## Что надо сделать

Выьрать любой VDS хостинг и развернуть сервак

1. Создать сервер на Ubuntu 22.04 LTS( мин 4Gb ОЗУ)
2. Зайти под root и склонировать репозиторий
3. ```git clone https://github.com/MaksimKazakov/JSSuiVDS.git```
4. Перейти в каталог `cd JSSuiVDS`
5. `chmod +x build1.sh`
6. `./build1.sh`
7. Следовать указаниям на экране
8. После установки Jenkins установить плагины (http://${IP_ADDRESS}:8888/manage/pluginManager/available):
    - Allure
    - Text File Operations
    - Post build task
    
