---
title: 修改TheHive的jar包里面js源码流程记录
key: modify_thehive_jar_js
layout: article
date: '2019-05-29 14:57:00'
tags: java
typora-root-url: ../../iblog
---

### 背景:

需求是要在TheHive的Case页面下的observables下添加按钮批量录入IOC.  需要更改TheHive的源码. 修改一些页面js. 但是js是在jar包当中的.

### 操作流程:

1. 进入jar包所在目录

   ```bash
    cd /opt/thehive/lib
   ```

2. 将需要的jar包通过sz回传到本机  **(需要注意选择本机目录的时候千万不能有中文, 否则sz接收不到)**

   ```bash
   sz org.cert-bdf.thehive-3.0.9-assets.jar
   ```

3. 利用解压工具加压jar包

4. 修改js文件    org.cert-bdf.thehive-3.0.9-assets/ui/scripts/scripts.87c22dca.js

5. 重新打包成jar包

   ```bash
   cd    org.cert-bdf.thehive-3.0.9-assets
   jar cvf org.cert-bdf.thehive-3.0.9-assets.jar *
   ```

6. 通过rz回传到服务器  ( 需要注意文件需要root权限 所以无论是rz还是sudo rz都不行 必须先su切换到root用户 ,在rz回传

   ```bash
   su   输入密码
   mv org.cert-bdf.thehive-3.0.9-assets.jar org.cert-bdf.thehive-3.0.9-assets.jar.copy
   rz (必须正常窗口用root执行rz 在tmux的状态下好像不行)
   ll org.cert-bdf.thehive-3.0.9-ass*  通过ll查看一下是否回传成功
   ```

7. 重启TheHive

   ```bash
    sudo service thehive stop
    sudo service thehive start
   ```

 这样才算正式生效.

![](https://imgs.zhangbaobao.cn/img/image-20190529150337847.png)