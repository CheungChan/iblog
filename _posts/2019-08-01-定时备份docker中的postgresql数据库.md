---
title: 定是备份docker中的postgresql数据库
key: crontab_bak_postgressql
layout: article
date: '2019-08-01 17:51:00'
tags: 技术 linux 数据库 docker
typora-root-url: ../../iblog
---

### Q: 定时备份docker中的postgresql数据库

### A: 问题可以分为两个子问题

1. 如何备份dacker中的postgresql
2. 如何开启定时任务, 执行备份脚本

pg_bak.sh ( 注意命令路径必须使用绝对路径)

```shell
#!/bin/sh
file="bak_$(date +"%Y%m%d_%H%M%S").sql"
/usr/bin/docker exec -t postgresql  pg_dump -U username -d dbname > "/data/pg_bak/${file}"
```

赋予脚本执行权限

```bash
chmod +x pg_bak.sh
```

crontab -e

```cron
# 用每分钟一次来调试
* * * * * . ~/.bash_profile; /data/pg_bak/pg_bak.sh
# 实际用每天11点钟
0 11 * * *  . ~/.bash_profile; /data/pg_bak/pg_bak.sh
```

### 知识点整理:

1.  用当前时间来命名文件

   ```shell
   file="bak_$(date +"%Y%m%d_%H%M%S").sql"
   ```

2. 用crontab执行shell脚本.shell脚本里面的命令必须用绝对路径`/usr/bin/docker`

3. 调试crontab日志 , 用mail

4. crontab -e配置文件里要使用环境变量的方式是`* * * * * . ~/.zshrc;  /xxx/yy.sh` 

5. 写完shell脚本之后一定要给shell脚本执行权限

6. 调试的时候cron可以用 * * * * *, 之后改, 分别代表意思是分 时 日 月 周