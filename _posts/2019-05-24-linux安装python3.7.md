---
title: linux安装python3.7
layout: post
date: '2019-05-24 20:00:00'
categories: 技术 python3 python3.7 python ubuntu linux
---

### ubuntu18.04安装python3.7.3
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