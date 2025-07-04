# Инструкция по настройки Canon-LBP6020

За основу взята инструкция (https://pc.ru/articles/alt-linux-canon-capt)
Огромная благодарность автору данной статьи!

## Установка принтера Canon-LBP6020

1.Заходим на официальный сайт Canon, и скачиваем драйвера для Linux

2.По завершению скачивания архива с драйверами, открываем терминал, в котором переходим в сессию под суперпользователем.

```bash
su -
```

3.Переходим в терминале в директорию со скачанным архивом, и распаковываем его.

```bash
tar -xf linux-capt-drv-v271-uken.tar.gz
```

4.Переходим в директорию с распакованным драйвером. В статье в качестве примера будет выступать 64-разрядный драйвер.

```bash
cd linux-capt-drv-v271-uken/64-bit_Driver/RPM
```

5.В данной директории будут два RPM файла, которые требуется установить в системе.

```bash
apt-get install ./cndrvcups-common-3.21-1.x86_64.rpm ./cndrvcups-capt-2.71-1.x86_64.rpm --assume-yes
```

6.После установки пакетов, добавим правило для udev, чтобы не зависеть от назначенного принтеру порта.

```bash
touch /etc/udev/rules.d/85-canon-capt.rules && \
echo 'KERNEL=="lp*", ACTION=="add", ATTRS{product}=="Canon CAPT USB Device", SYMLINK+="usb/capt"' > /etc/udev/rules.d/85-canon-capt.rules && \
echo 'KERNEL=="lp*", ACTION=="add", ATTRS{product}=="Canon CAPT USB Printer", SYMLINK+="usb/capt"' >> /etc/udev/rules.d/85-canon-capt.rules && \
echo 'KERNEL=="lp*", ACTION=="add", ATTRS{product}=="LBP6030/6030B/6018L", SYMLINK+="usb/capt"' >> /etc/udev/rules.d/85-canon-capt.rules

```

7.Указываем udev о необходимости перезагрузить список правил.

```bash
udevadm control --reload-rules
```

8.Теперь нужно зарегистрировать принтер в системе. Делается это следующей командой:

```bash
lpadmin -p "[ИМЯ ПРИНТЕРА]" -m [PPD файл] -v ccp://localhost:59687 -E
```

  Пример с 6020:

```bash
lpadmin -p "Canon-LBP6020" -m CNCUPSLBP6020CAPTK.ppd -v ccp://localhost:59687 -E
```

9.Регистрируем принтер в CCPD, используя ранее заданное имя принтера в команде lpadmin.

```bash
ccpdadmin -p "Canon-LBP6020" -o /dev/usb/capt
```

10.Создадим сервис, который будет отвечать за работу программы ccpd, необходимой для печати принтера. Для этого, создаем текстовый файл при помощи любого текстового редактора (например nano):

```bash
nano /etc/systemd/system/ccpd.service
```

  И вносим туда следующее содержимое:

```
[Unit]
Description=CCPD Printing Daemon

[Service]
ExecStart=/usr/sbin/ccpd
TimeoutSec=5
Type=forking

[Install]
WantedBy=multi-user.target
```

11.Удаляем сервис для init, который на текущий момент уже не актуален.

```bash
rm -f /etc/rc.d/init.d/ccpd
```

12.Перезагружаем список сервисов systemd.

```bash
systemctl daemon-reload
```

13.Включаем свежесозданный сервис ccpd.

```bash
systemctl enable ccpd
```

14.Перезагружаем и запускаем сервисы ccpd и cups.

```bash
systemctl restart ccpd cups
```

## P.S. При попытке печати ничего не происходило

CUPS выдавал: "Can't connect to CCPD: Connection refused" В итоге печать успешно заработала после установки доп. пакета:

```bash
apt-get install initscripts-compat-fedora
```

## Работа по сети

1.На хостовой машине меняем конфиг cups

```bash
nano /etc/cups/cupsd.conf
```

  Меняем все до `<Location /admin>`

```
LogLevel warn
PageLogFormat
MaxLogSize 1m
ErrorPolicy retry-job
# Allow remote access
Listen 0.0.0.0:631
Listen /var/run/cups/cups.sock
# Share local printers on the local network.
Browsing On
BrowseLocalProtocols dnssd
DefaultAuthType Basic
WebInterface Yes
IdleExitTimeout 150
<Location />
  # Allow shared printing...
  Order allow,deny
  Allow all
</Location>

<Location /printers/Canon-LBP6020>
  Order allow,deny
  Allow @LOCAL
</Location>
```

1.1.После перезагрузить cups

```bash
systemctl restart cups
```

2.На клиентской машине переходим в "Администрирование -> Параметры печати" Нажимаем кнопку "Добавить" в меню переходим "Сетевой принтер -> Поиск сетевого принтера" и вводим IP хостовой машины. Запросит авторизацию жмем "Отмена" и далее по наитию.
