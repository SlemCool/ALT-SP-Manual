#!/bin/bash
# Скрипт первичной настройки АРМ
# Автор: [Андрей Кагадий]
# Версия: 1.0
# Описание: Устанавливает зависимости, копирует файлы, настраивает окружение.

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите скрипт с правами root."
    exit 1
fi

echo "Добавляем константы" 
SERVER_IP="192.168.16.13"
DISP_SERVER="192.168.17.111"
CLINIC_SERVER="192.168.16.4"
REPO_ARCH=("x86_64 classic gostcrypto" "x86_64-i586 classic" "noarch classic")

read -p "Введите имя пользователя, под которым будет работать клиент:" UserName
if [ -z "$UserName" ]; then
    echo "Имя пользователя не может быть пустым."
    exit 1
fi
read -s -p "Введите пароль от пользователя root на сервере БД:" BDPass
if [ -z "$BDPass" ]; then
    echo "Пароль не может быть пустым."
    exit 1
fi

echo "Добавляем репозитории CF2"
for arch in "${REPO_ARCH[@]}"; do
    apt-repo add "rpm [cert8] http://update.altsp.su/pub/distributions/ALTLinux CF2/branch/$arch"
done

echo "Обновляем apt"
apt-get update || { echo "Failed to update package lists."; exit 1; }

install_fonts() {
    echo "Устанавливаем шрифты"
    apt-get install -y fonts-ttf-ms fonts-ttf-PTAstra fonts-ttf-paratype-pt-* \
        fonts-ttf-liberation fonts-ttf-dejavu fonts-ttf-XO || { echo "Ошибка установки шрифтов"; exit 1; }
}

install_fonts

echo "Устанавливаем необходимые пакеты"
apt-get install -y \
    python-module-PyQt4 python-module-requests python-module-pyserial \
    python-module-isodate python-module-pip python-dev python-modules-distutils \
    nano sshpass ftp sudo wget gcc swig libqt4-sql-mysql libmysqlclient21

echo "Копируем клиент распаковываем и даём права"
sshpass -p "$BDPass" scp -o StrictHostKeyChecking=no root@$SERVER_IP:/var/ftp/pub/update/client_lin.tar.gz /opt/
tar xzf /opt/client_lin.tar.gz -C /opt
chmod -R 777 /opt/client

echo "Создаем ярлык на рабочем столе"
cp /opt/client/Samson_AutoUP.desktop "/home/$UserName/Рабочий стол/"
chmod 777 "/home/$UserName/Рабочий стол/Samson_AutoUP.desktop"

echo "Устанавливаем шрифты для печати штрихкодов"
cp /opt/client/install/fonts/*.ttf /usr/share/fonts/ttf/
fc-cache -f -v

echo "Обновляем pip2"
pip2 install --upgrade setuptools
pip2 install --upgrade pip

echo "Устанавливаем зависимости"
pip2 install wheel
pip2 install /opt/client/install/ZSI-2.1-a1.tar.gz
pip2 install /opt/client/install/PyXML-0.8.4.tar.gz
sed -i '/pyscard/d' /opt/client/requirements.txt
pip2 install -r /opt/client/requirements.txt

echo "Удаляем репозитории CF2"
for arch in "${REPO_ARCH[@]}"; do
    apt-repo rm "rpm [cert8] http://update.altsp.su/pub/distributions/ALTLinux CF2/branch/$arch"
done

echo "Удаляем клиент"
rm -f /opt/client_lin.tar.gz

echo "Копируем конфиг"
mkdir -p /home/$UserName/.config/samson-vista
sshpass -p "$BDPass" scp root@$SERVER_IP:/var/ftp/pub/disp-config/S11App.ini /home/$UserName/.config/samson-vista/S11App.ini
chown -R $UserName:$UserName /home/$UserName/.config/samson-vista
chmod 775 /home/$UserName/.config/samson-vista/S11App.ini

echo "Устанавливаем Яндекс.Браузер"
apt-get install -y yandex-browser-stable

echo "Скачиваем и устанавливаем КриптоПро"
sshpass -p "$BDPass" scp root@$SERVER_IP:/var/ftp/pub/disp-config/linux-amd64.tgz .
tar -xf linux-amd64.tgz
sh ./linux-amd64/install_gui.sh
rm -rf linux-amd64.tgz linux-amd64


echo "Создаем папки для монтирования"
mkdir /mnt/PUBLIC\(DISP\)
mkdir /mnt/PUBLIC\(CLINIC\)


echo "Настраиваем монтирование"
read -p "Введите имя пользователя для паблика Диспансера:" DispUser
if [ -z "$DispUser" ]; then
    echo "Имя пользователя не может быть пустым."
    exit 1
fi

read -s -p "Введите пароль от пользователя kaa для паблика Диспансера:" DispPass
if [ -z "$DispPass" ]; then
    echo "Пароль не может быть пустым."
    exit 1
fi

echo

read -p "Введите имя пользователя для паблика Стационара:" ClinicUser
if [ -z "$ClinicUser" ]; then
    echo "Имя пользователя не может быть пустым."
    exit 1
fi

read -s -p "Введите пароль от пользователя kaa для паблика Стационара:" ClinicPass
if [ -z "$ClinicPass" ]; then
    echo "Пароль не может быть пустым."
    exit 1
fi

echo -e "username=$DispUser\npassword=$DispPass" | tee /etc/samba/disp_cred > /dev/null
echo -e "username=$ClinicUser\npassword=$ClinicPass" | tee /etc/samba/clinic_cred > /dev/null

chmod 600 /etc/samba/disp_cred
chmod 600 /etc/samba/clinic_cred

echo "//$DISP_SERVER/public /mnt/PUBLIC(DISP) cifs users,_netdev,nofail,credentials=/etc/samba/disp_cred,file_mode=0777,dir_mode=0777,iocharset=utf8 0 0" | tee -a /etc/fstab
echo "//$CLINIC_SERVER/public /mnt/PUBLIC(CLINIC) cifs users,_netdev,nofail,credentials=/etc/samba/clinic_cred,file_mode=0777,dir_mode=0777,iocharset=utf8 0 0" | tee -a /etc/fstab

mount -a

echo "Создаем ярлыки на рабочем столе"
ln -s /mnt/PUBLIC\(DISP\) "/home/$UserName/Рабочий стол/"
chmod 777 "/home/$UserName/Рабочий стол/PUBLIC(DISP)"

ln -s /mnt/PUBLIC\(CLINIC\) "/home/$UserName/Рабочий стол/"
chmod 777 "/home/$UserName/Рабочий стол/PUBLIC(CLINIC)"

echo "Копируем ярлык ПЦЛЛО на рабочий стол"
sshpass -p "$BDPass" scp root@$SERVER_IP:/var/ftp/pub/disp-config/ПЦЛЛО.desktop "/home/$UserName/Рабочий стол/"
chmod 777 "/home/$UserName/Рабочий стол/ПЦЛЛО.desktop"

echo "Проверка существования $UserName пользователя"
if ! id "$UserName" &>/dev/null; then
    echo "Пользователь $UserName не существует."
    exit 1
fi

echo "Устанавливаем Vino VNC"
apt-get install -y vino-mate || { echo "Ошибка установки Vino VNC"; exit 1; }

echo "Выходим из админской сессии и продолжаем от имени пользователя $UserName"
su - "$UserName" -c "
export DISPLAY=:0
dconf write /org/gnome/desktop/remote-access/enabled true
dconf write /org/gnome/desktop/remote-access/require-encryption false
dconf write /org/gnome/desktop/remote-access/prompt-enabled false
dconf write /org/mate/pluma/auto-detected-encodings \"['UTF-8', 'WINDOWS-1251', 'GBK', 'ISO-8859-15', 'UTF-16']\"
"
echo "Настройка Vino VNC завершена!"

echo "Установка завершена! Перезагрузите АРМ для применения всех изменений."