# Инструкция по настройке принтера UFR на примере Canon-LBP6030

За основу взята инструкция (https://www.altlinux.org/%D0%9F%D1%80%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D1%8B_Canon)

## Установка принтера Canon-LBP6030

1.Скидываем папку с драйверами в домашнюю папку "linux-UFRIILT-drv-v500-uken"

2.Открываем терминал, в котором переходим в сессию под суперпользователем.

```bash
su -
```

4.Переходим в директорию с распакованным драйвером. В статье в качестве примера будет выступать 64-разрядный драйвер.

```bash
cd linux-UFRIILT-drv-v500-uken/64-bit_Driver/RPM
```

5.Предварительно установите данные пакеты (возможно часть у вас уже установлена):

``bash
apt-get install libturbojpeg i586-libturbojpeg i586-libbeecrypt7 libbeecrypt7 libbeecrypt-devel i586-libbeecrypt-devel i586-libjbig  libjbig i586-libjbig-devel.32bit jbig-utils libjbig-devel i586-libxml2 libxml2 i586-glibc-core i586-libstdc++6 libstdc++6 libgcrypt20 i586-libgcrypt20 i586-libgcrypt-devel libgcrypt-devel i586-libjpeg.32bit i586-libzstd.32bit libzstd libglade i586-libgladeui2.0.32bit i586-libglade.32bit libglade-devel libncurses i586-libncurses.32bit i586-liblzma.32bit
```

6.В данной директории будет RPM файл, который требуется установить в систему.

```bash
apt-get install ./cnrdrvcups-ufr2lt-uk-5.00-1.x86_64.rpm --assume-yes
```

7.Далее устанавливаем через системное меню.

## P.S. При попытке печати ничего не происходило

CUPS выдавал: "Can't connect to CCPD: Connection refused" В итоге печать успешно заработала после установки доп. пакета:

```bash
apt-get install initscripts-compat-fedora
```
