---
title: postgresql使用docker搭建与备份
key: postgresql_init_and_bak
layout: article
date: '2019-08-17 17:51:00'
tags: 技术 数据库 docker
typora-root-url: ../../iblog
---

### postgresql使用docker搭建

#### 使用docker拉取镜像

```bash
docker pull postgres
```

#### 启动容器

```bash
docker run --name postgresql -e POSTGRES_PASSWORD=mypassword -e POSTGRES_USER=myuser -p 5432:5432 -v /data/db_pg:/home/data -d postgres
```

#### 查看容器

```bash
docker ps  -a
```

#### 若服务未启动

```bash
docker start postgresql
```

#### 进入容器

```bash
docker exec -it postgresql bash
```

#### 登录postgresql

```bash
psql -U  root
```

#### 修改密码

```bash
\password username
```

#### 创建用户

```sql
create user myuser with password 'mypassword'
```

#### 创建用户数据库

```sql
create database mydb owner myuser
```

#### 赋予权限

```sql
grant all privileges on database mydb to myuser
```

#### 退出

```sql
\q
```

#### 如果要外部执行sql

```sql
psql mydb <  mydb_bak.sql
```

#### 登录命令

```bash
psql -U myuser -d mydb -h 127.0.0.1 -p 5432
```

#### 控制台命令

- \h：查看SQL命令的解释，比如\h select。
- \?：查看psql命令列表。
- \l：列出所有数据库。
- \c [database_name]：连接其他数据库。
- \d：列出当前数据库的所有表格。
- \d [table_name]：列出某一张表格的结构。
- \du：列出所有用户。
- \e：打开文本编辑器。
- \conninfo：列出当前数据库和连接的信息。

#### 数据库操作

 创建新表 

```sql
CREATE TABLE user_tbl(name VARCHAR(20), signup_date DATE);
```

插入数据 

```sql
INSERT INTO user_tbl(name, signup_date) VALUES('张三', '2013-12-22');
```

 选择记录 

```sql
SELECT * FROM user_tbl;
```

更新数据 

```sql
UPDATE user_tbl set name = '李四' WHERE name = '张三';
```

删除记录 

```bash
DELETE FROM user_tbl WHERE name = '李四' ;
```

添加栏位 

```sql
ALTER TABLE user_tbl ADD email VARCHAR(40);
```

更新结构 

```sql
ALTER TABLE user_tbl ALTER COLUMN signup_date SET NOT NULL;
```

更名栏位 

```sql
ALTER TABLE user_tbl RENAME COLUMN signup_date TO signup;
```

删除栏位 

```sql
ALTER TABLE user_tbl DROP COLUMN email;
```

表格更名 

```sql
ALTER TABLE user_tbl RENAME TO backup_tbl;
```

删除表格 

```sql
DROP TABLE IF EXISTS backup_tbl;
```

创建备份数据库:

```sql
create database threatbook_prod_bak_20190722  owner threatbook;

grant all privileges on database threatbook_prod_bak_20190722 to threatbook;
```

### docker镜像中的postgresql 备份还原

备份:

```bash
docker exec -t postgresql  pg_dump -U threatbook -d threatbook > dump_`date +%Y-%m-%d"_"%H_%M_%S`.sql
```

还原:

```bash
 cat dump_2019-08-01_15_18_06.sql| docker exec -i postgresql  psql -U threatbook
```



