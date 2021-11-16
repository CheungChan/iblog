---
title: centos安装最新版python
key: centosnewpython
layout: article
date: '2020-12-08 17:00:00'
tags:  python
typora-root-url: ../../iblog

---

## 需求

centos上面安装最新版python

## 实现

python3.6可以直接 yum install python36即可。后面的版本需要编译安装

```bash
version=3.7.9
#version=3.9.1
sudo yum install -y  gcc openssl-devel bzip2-devel libffi-devel zlib-devel readline-devel  tk-devel tcl-devel   sqlite-devel xz-devel
wget https://www.python.org/ftp/python/$version/Python-$version.tgz 
tar xzf Python-$version.tgz 

cd Python-$version
sudo ./configure --enable-optimizations 
sudo make altinstall
```

若出现报错

```bash
Cannot import name "Feature" from "setuptools" in version 46.0.0
```



执行

```bash
pip install setuptools==45
```

