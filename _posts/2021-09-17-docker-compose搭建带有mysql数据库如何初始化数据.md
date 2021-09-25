---
Title: docker-compose搭建带有mysql数据库如何初始化数据
key: mysql_docker_compose_init_data
layout: article
date: '2021-09-18 20:15:00'
tags: 技术 docker mysql
typora-root-url: ../../iblog


---
## 问题的源起

搭建服务的时候如果服务依赖myql，那么需要docker-compose拉取mysql容器，然后执行一下初始化数据库的脚本创建数据库用户，创建数据库，创建表， 插入一些初始化数据。然后才能启动服务。

#### 问题一

如何让server一直wait知道mysql初始化完成再启动。

#### 问题二

mysql初始化数据放在哪里？我一开始想打包一个自己的mysql镜像，把数据都打进去。但是mysql的官方容器默认是VOLUMN /var/lib/mysql的。 所以即使有数据变更，创建了新的数据库数据表，docker commit的时候其他机器拉取镜像跑容器的时候还是没有数据。哪里放初始化数据，哪里放业务代码。

#### 问题三

myql的默认配置很垃圾，一般都需要自己设置编码utfmb4,设置时区等等，该如何设置，在哪里设置。还有root密码怎么根据docker-compose提供的密码进行设置。

## 思路

server等待mysql可以写一个wait.sh 一直判断mysql是否可以建立连接，不可以继续等待，等可以连接了再去启动server。

把数据提交到镜像里的方案不可行。那么可以把mysql的初始化sql脚本放在/docker-entrypoint-initdb.d下面。把sql脚本打包到镜像里面，而不是把数据打包到镜像里面。这样容器首次启动的时候会执行脚本，再次启动就不会在执行脚本了。

配置文件也是作为自定义mysql镜像的时候把配置文件拷贝进去，需要mysql有自己一份dockerfile。

## 解决方案

由于保护隐私的需要，项目名称已打码，配置文件中名称统一修改为my_business。

![](http://img.azhangbaobao.cn/img/20210926010409.png)

如图所示，在服务Dockerfile一层，新建一个wait.sh

```shell
#!/bin/sh

set -e

db="$1"
shift
user="$1"
shift
password="$1"
shift
port="$1"
shift
cmd="$@"


# 把密码，端口替换掉
cat>/opt/my_business/config.ini<<EOF

# 其他配置部分省略掉
[database]
type = mysql
max_open = 50
max_idle = 20
max_size = 1
url = root:${password}@tcp(127.0.0.1:${port})/my_business?charset=utf8mb4&parseTime=true&loc=Local
debug = true

[database.logger]
Path = logs/sql
Level = all
Stdout = true
EOF

until mysql -u"$user" -p"$password" -h 127.0.0.1 -P $port
do
        >&2 echo  "mysql is not ready, please wait a minute..."
        sleep 10
done

>&2 echo "MySQL is up - so server can up"
exec $cmd
```

在dockerfile里面拷贝wait.sh到server的镜像里

```dockerfile
FROM alpine:latest

ENV my_business_VERSION 2.6.1

# Download and install glibc
# RUN #apk update && \
#  apk add --no-cache curl tzdata mysql-client && \
#  cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
#  curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
RUN apk add --no-cache mysql-client
# RUN apk add --no-cache curl

COPY my_business.tar.gz /opt/my_business.tar.gz

RUN mkdir -p /opt/my_business && \
  tar -zxvf /opt/my_business.tar.gz -C /opt/ && \
  rm -f /opt/my_business.tar.gz

EXPOSE 4433
EXPOSE 4434
COPY wait.sh /wait.sh

WORKDIR /opt/my_business
VOLUME ["/opt/my_business/logs"]

CMD ["./server"]

```

把创建业务表的sql放在 myql/sql/init_xxx.sql里面。

Init_xxx.sql忽略，你可以自己设置

然后再mysql/Dockerfile里面把sql语句放在启动目录下

```bash
FROM mysql:5.7
ADD mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
WORKDIR /docker-entrypoint-initdb.d
ENV LANG=C.UTF-8
ADD sql/init_my_business.sql .

```

这里有一个mysql的配置文件，示例如下

```ini
[client]
port=3306
socket = /var/run/mysqld/mysqld.sock
[mysql]
no-auto-rehash
auto-rehash
default-character-set=utf8mb4
[mysqld]
###basic settings
server-id = 2
pid-file    = /var/run/mysqld/mysqld.pid
socket        = /var/run/mysqld/mysqld.sock
datadir        = /var/lib/mysql
log-error    = /var/lib/mysql/error.log
default_time_zone='+08:00'
# By default we only accept connections from localhost
#bind-address    = 127.0.0.1
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
character-set-server = utf8mb4
sql_mode="NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
default-storage-engine=INNODB
transaction_isolation = READ-COMMITTED
auto_increment_offset = 1
connect_timeout = 20
max_connections = 3500
wait_timeout=86400
interactive_timeout=86400
interactive_timeout = 7200
log_bin_trust_function_creators = 1
wait_timeout = 7200
sort_buffer_size = 32M
join_buffer_size = 128M
max_allowed_packet = 1024M
tmp_table_size = 2097152
explicit_defaults_for_timestamp = 1
read_buffer_size = 16M
read_rnd_buffer_size = 32M
query_cache_type = 1
query_cache_size = 2M
table_open_cache = 1500
table_definition_cache = 1000
thread_cache_size = 768
back_log = 3000
open_files_limit = 65536
skip-name-resolve
########log settings########
log-output=FILE
general_log = ON
general_log_file=/var/lib/mysql/general.log
slow_query_log = ON
slow_query_log_file=/var/lib/mysql/slowquery.log
long_query_time=10
#log-error=/var/lib/mysql/error.log
log_queries_not_using_indexes = OFF
log_throttle_queries_not_using_indexes = 0
#expire_logs_days = 120
min_examined_row_limit = 100
########innodb settings########
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_buffer_pool_size = 6144M
innodb_file_per_table = on
innodb_buffer_pool_instances = 20
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_log_file_size = 300M
innodb_log_files_in_group = 2
innodb_log_buffer_size = 16M
innodb_undo_logs = 128
#innodb_undo_tablespaces = 3
#innodb_undo_log_truncate = 1
#innodb_max_undo_log_size = 2G
innodb_flush_method = O_DIRECT
innodb_flush_neighbors = 1
innodb_purge_threads = 4
innodb_large_prefix = 1
innodb_thread_concurrency = 64
innodb_print_all_deadlocks = 1
innodb_strict_mode = 1
innodb_sort_buffer_size = 64M
innodb_flush_log_at_trx_commit=1
innodb_autoextend_increment=64
innodb_concurrency_tickets=5000
innodb_old_blocks_time=1000
innodb_open_files=65536
innodb_stats_on_metadata=0
innodb_file_per_table=1
innodb_checksum_algorithm=0
#innodb_data_file_path=ibdata1:60M;ibdata2:60M;autoextend:max:1G
innodb_data_file_path = ibdata1:12M:autoextend
#innodb_temp_data_file_path = ibtmp1:500M:autoextend:max:20G
#innodb_buffer_pool_dump_pct = 40
#innodb_page_cleaners = 4
#innodb_purge_rseg_truncate_frequency = 128
binlog_gtid_simple_recovery=1
#log_timestamps=system
##############
delayed_insert_limit = 100
delayed_insert_timeout = 300
delayed_queue_size = 1000
delay_key_write = ON
disconnect_on_expired_password = ON
div_precision_increment = 4
end_markers_in_json = OFF
eq_range_index_dive_limit = 10
innodb_adaptive_flushing = ON
innodb_adaptive_hash_index = ON
innodb_adaptive_max_sleep_delay = 150000
#innodb_additional_mem_pool_size = 2097152
innodb_autoextend_increment = 64
innodb_autoinc_lock_mode = 1
```

编写docker-compose.yml文件

```yaml
version: "3.7"
services:
  web:
    image: threatbook/my_business-server:2.6.1
    network_mode: "host"
    container_name: my_business-server # 容器名
    restart: always
    volumes:
      - "./logs:/opt/my_business/logs"
    depends_on:
      - db
    command: sh /wait.sh my_business root 1234567 3306 /opt/my_business/server

  db:
    image: threatbook/my_business-mysql:2.6.1
#    build: ./mysql
    restart: always
    container_name: my_business-mysql-db # 容器名
    environment:
      - MYSQL_ROOT_PASSWORD=1234567
      - TZ=Asia/Shanghai
    ports:
      - 3306:3306
    volumes:
      - ./data:/var/lib/mysql
    command: --character-set-server=utf8mb4
      --collation-server=utf8mb4_general_ci
      --explicit_defaults_for_timestamp=true
      --lower_case_table_names=1
      --default-time-zone=+08:00


```

这样，会拉起两个容器。server会wait等待mysql初始化完成再启动，等待时间较长，可能3分钟左右。

由于两个镜像都需要build，可以特意写一个build脚本  build.sh

```bash
if [ ! -n "$1" ] ;then
    echo "please input version!"
    exit 1
else
  version=$1
fi

echo "build docker image $version"
docker rmi  -f cheungchan/my_business-server:$version
docker build -f ./Dockerfile -t  cheungchan/my_business-server:$version .
echo "hfish docker build complete"
cd mysql
docker rmi -f cheungchan/my_business-mysql:$version
docker build --no-cache  -f ./Dockerfile -t cheungchan/my_business-mysql:$version .
cd ..
echo "hfish mysql docker build complete"
echo "you can try modify docker-compose.yml to right version and then 'docker-compose up' now"
```

打包好镜像之后再 docker-compose up

