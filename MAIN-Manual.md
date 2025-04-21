Автор: Андрей Кагадий
# Установка Alt Linux

## Первичная настройка ssh

Работа выполняется в Windows на PowerShell.

Создаем переменные окружения с текущим именем пользователя АРМ и IP адресом

```powershell
$ArmUser="<userName>"
```

```powershell
$IP="<IP>"
```

Пробрасываем ssh ключ для авторизации

```powershell
cat ~/.ssh/id_ed25519.pub | ssh $ArmUser@$IP `
"mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys \`
&& chmod 600 ~/.ssh/authorized_keys"
```

Теперь можем подключится по ssh

```powershell
 ssh $ArmUser@$IP
```

Включаем админа
```bash
su -
```

Копируем скрипт
```bash
scp root@192.168.16.13:/var/ftp/pub/disp-config/install_script_alt.sh /opt/
```

Раскомментируем репозиторий
```bash
sed -i 's/#rpm \[cert8\] http/rpm \[cert8\] http/' /etc/apt/sources.list.d/altsp.list
```

Обновляем список пакетов
```bash
apt-get update && \
apt-get install -y newt52
```

#### Устанавливаем всё скриптом(Если руками то пропустить этот шаг)
```bash
sh /opt/install_script_alt.sh
```

## Если решили руками. Настройка АРМ

Включаем режим "бога"
```bash
su -
```

Добавить переменную с именем пользователя
```bash
UserName="<userName>"
```

Устанавливаем шрифты
```
apt-get install -y \
    fonts-ttf-ms \
    fonts-ttf-PTAstra \
    fonts-ttf-paratype-pt-* \
    fonts-ttf-liberation \
    fonts-ttf-dejavu \
    fonts-ttf-XO 
```


### Установка МИС Самсон

Добавить репы CF2
```bash
RepoArch=("x86_64 classic gostcrypto" "x86_64-i586 classic" "noarch classic")
```

```bash
for arch in "${RepoArch[@]}"; do
    apt-repo add "rpm [cert8] http://update.altsp.su/pub/distributions/ALTLinux CF2/branch/$arch"
done
```

Получить списки пакетов
```bash
apt-get update
```

Установить необходимые пакеты
```bash
apt-get install -y \
    python-module-PyQt4 python-module-requests python-module-pyserial \
    python-module-isodate python-module-pip python-dev python-modules-distutils \
    nano ftp sudo wget gcc swig libqt4-sql-mysql libmysqlclient21
```

Проверить версию, должна быть libmysqlclient21-8.0.40-alt1.x86_64
```bash
rpm -qa | grep libmysqlclient21
```

Скопировать с сервера каталог /var/ftp/pub/update/client_lin.tar.gz в директорию /opt
где 192.168.16.13 – IP-адрес сервера БД
```bash
scp root@192.168.16.13:/var/ftp/pub/update/client_lin.tar.gz /opt/
```

Распаковать клиент
```bash
tar xzf /opt/client_lin.tar.gz -C /opt
```

Выдаем все права каталогу с клиентом
```bash
chmod -R 777 /opt/client
```

Создаем ярлык на рабочем столе
```bash
cp /opt/client/Samson_AutoUP.desktop "/home/$UserName/Рабочий стол/" \
&& chmod 777 "/home/$UserName/Рабочий стол/Samson_AutoUP.desktop"
```

Устанавливаем шрифты для печати штрихкода и другие
```bash
cp /opt/client/install/fonts/*.ttf /usr/share/fonts/ttf/
```

Обновить кэш шрифтов
```bash
fc-cache -f -v
```

Обновить pip2
```bash
pip2 install --upgrade setuptools \
&& pip2 install --upgrade pip
```

Установить нужные пакеты
```bash
pip2 install wheel \
&& pip2 install /opt/client/install/ZSI-2.1-a1.tar.gz \
&& pip2 install /opt/client/install/PyXML-0.8.4.tar.gz
```

Исключить пакет вызывающий ошибку
```bash
sed -i '/pyscard/d' /opt/client/requirements.txt
```

Установить зависимости
```bash
pip2 install -r /opt/client/requirements.txt
```

Завершение установки
Удалить репы CF2 https://www.basealt.ru/altsp
```bash
for arch in "${RepoArch[@]}"; do
    apt-repo rm "rpm [cert8] http://update.altsp.su/pub/distributions/ALTLinux CF2/branch/$arch"
done
```

Скинуть готовый конфиг(диспансера)
```bash
mkdir -p /home/$UserName/.config/samson-vista && \
scp root@192.168.16.13:/var/ftp/pub/disp-config/S11App.ini /home/$UserName/.config/samson-vista/S11App.ini
```


### Установка Яндекс браузера.

```bash
apt-get install -y yandex-browser-stable
```


### Установка КриптоПро

Скопировать с сервера каталог /var/ftp/pub/update/linux-amd64.tgz
где 192.168.16.13 – IP-адрес сервера БД
```bash
scp root@192.168.16.13:/var/ftp/pub/disp-config/linux-amd64.tgz .
```

Распаковывать
```bash
tar -xf linux-amd64.tgz
```

Запустить инсталяшку. Выбираем все пункты кроме второго
```bash
sh ./linux-amd64/install_gui.sh
```
Инструкция на всякий:
https://www.altlinux.org/%D0%9A%D1%80%D0%B8%D0%BF%D1%82%D0%BE%D0%9F%D1%80%D0%BE


### Подключение сетевых дисков SMB.

Создаем папки для присоединения
```bash
mkdir /mnt/PUBLIC\(DISP\) && \
mkdir /mnt/PUBLIC\(CLINIC\)
```

Создание файлов с кредлами
```bash
echo -e "username=<userName>\npassword=<userPass>" | tee /etc/samba/disp_cred > /dev/null
```
```bash
echo -e "username=<userName>\npassword=<userPass>" | tee /etc/samba/clinic_cred > /dev/null
```

Для безопасности этот файл должен быть доступен только для root:
```bash
chmod 600 /etc/samba/disp_cred && \
chmod 600 /etc/samba/clinic_cred
```

Что бы примонтировались при старте системы добавляем запись в fstab
```bash
echo "//192.168.17.111/public /mnt/PUBLIC(DISP) cifs users,_netdev,nofail,credentials=/etc/samba/disp_cred,file_mode=0777,dir_mode=0777,iocharset=utf8 0 0" | tee -a /etc/fstab
```
```bash
echo "//192.168.16.4/public /mnt/PUBLIC(CLINIC) cifs users,_netdev,nofail,credentials=/etc/samba/clinic_cred,file_mode=0777,dir_mode=0777,iocharset=utf8 0 0" | tee -a /etc/fstab
```

После добавления строк в /etc/fstab, примонтируйте ресурсы с помощью команды:
```bash
mount -a
```

Создаем ярлыки на рабочий стол.
```bash
ln -s /mnt/PUBLIC\(DISP\) "/home/$UserName/Рабочий стол/" \
&& chmod 777 "/home/$UserName/Рабочий стол/PUBLIC(DISP)"
```

```bash
ln -s /mnt/PUBLIC\(CLINIC\) "/home/$UserName/Рабочий стол/" \
&& chmod 777 "/home/$UserName/Рабочий стол/PUBLIC(CLINIC)"
```

Так же скидываем ярлык ПЦ ЛЛО
```bash
scp root@192.168.16.13:/var/ftp/pub/disp-config/ПЦЛЛО.desktop "/home/$UserName/Рабочий стол/" \
&& chmod 777 "/home/$UserName/Рабочий стол/ПЦЛЛО.desktop"
```

### VNC и исправление переключения языков.

Установить vino
```bash
apt-get install -y vino-mate
```

!!!ВОЗМОЖНО НЕ НУЖНО
После изменения настроек перезапустите сервер Vino
При запуске подвисает консоль надо разобраться!!!
```bash
pkill vino-server && \
/usr/lib/vino-server &
```

!!! Выполнять из под пользователя !!!
```bash
exit
```

Включаем VNC
```bash
dconf write /org/gnome/desktop/remote-access/enabled true
dconf write /org/gnome/desktop/remote-access/require-encryption false
dconf write /org/gnome/desktop/remote-access/prompt-enabled false
```

Чиним кодировку в блокноте
```bash
dconf write /org/mate/pluma/auto-detected-encodings "['UTF-8', 'WINDOWS-1251', 'GBK', 'ISO-8859-15', 'UTF-16']"
```


Если не работает то руками

Перейдите к следующему пути:
org -> gnome -> desktop -> remote-access
Найдите параметр require-encryption и отключите его (снимите галочку).
Заодно поменять настройки для блокнота.
org -> mate -> pluma -> auto-detected-encodings 
Пользовательское значение [‘UTF-8’, ‘WINDOWS-1251’, …остальные]
