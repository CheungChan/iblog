---
title: linux安装python3.7
key: linux_install_python3.7
layout: article
date: '2019-05-24 20:00:00'
tags: 技术 python linux
typora-root-url: ../../iblog
---

## 软件包管理器安装

### ubuntu18.04使用apt安装python3.7.3

1. 首先更新软件包列表并安装先决条件：
```bash
sudo apt update
sudo apt install software-properties-common
```
2. 接下来，将deadsnakes PPA添加到您的源列表：
```bash
sudo add-apt-repository ppa:deadsnakes/ppa
```
提示时按Enter继续：
```bash
Output
Press [ENTER] to continue or Ctrl-c to cancel adding it.
```
3. 启用存储库后，使用以下命令安装Python 3.7：
```bash
sudo apt install python3.7
```
4. 此时，Python 3.7已安装在您的Ubuntu系统上，随时可以使用。您可以输入以下命令进行验证：
```bash
python3.7 --version
```
```bash
Output
Python 3.7.3
```
### 接着安装pip3.7
```bash
wget https://bootstrap.pypa.io/get-pip.py
sudo python3.7 get-pip.py
```

## 编译安装



0. 怎样确定centos系统是不是7呢?

    ```bash
    cat /etc/redhat-release 
    ```

    就可以看到具体的centos版本

    ![image-20190529175359294](/img/image-20190529175359294.png)

       

    怎样确定ubuntu系统的版本呢?

    

    ```bash
    cat /etc/lsb-release
    ```

    ​	就可以看到具体的ubutnu系统版本    ![image-20190531165450552](/img/image-20190531165450552.png)

1. 安装依赖

   centos:

   ```bash
   yum install gcc openssl-devel bzip2-devel libffi-devel
   ```

   ubuntu:

   ```bash
   sudo apt-get install build-essential checkinstall
   sudo apt-get install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev
   ```

   

2. 下载python3.7.3并解压

   ```bash
   wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
   tar xzf Python-3.7.3.tgz
   ```

3. 安装python3.7.3

   ```bash
   cd Python-3.7.3
   ./configure --enable-optimizations --prefix=/usr/local/python3 --with-ssl
   sudo make altinstall
   ```

4. 创建软连接

   ```bash
   sudo rm /usr/bin/python3
   sudo rm /usr/bin/python3.7
   sudo rm /usr/bin/pip3
   sudo rm /usr/bin/pip3.7
   
   sudo ln -s /usr/local/python3/bin/python3.7 /usr/bin/python3
   sudo ln -s /usr/local/python3/bin/python3.7 /usr/bin/python3.7
   sudo ln -s /usr/local/python3/bin/pip3.7 /usr/bin/pip3
   sudo ln -s /usr/local/python3/bin/pip3.7 /usr/bin/pip3.7
   ```

5. 检查python版本

   ````bash
   python3.7 -V
   Python 3.7.3
   ````

   