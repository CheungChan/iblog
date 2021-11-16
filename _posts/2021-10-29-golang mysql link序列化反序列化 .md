---
Title: golang mysql link序列化反序列化
key: goland_mysql_dump_load
layout: article
date: '2021-10-29 15:50:00'
tags:  go
typora-root-url: ../../iblog

---
常量变量 option.go

```go
var (
	MysqlLinkFormat = "%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=true&loc=Local"
	MysqlLinkRegex  = regexp.MustCompile("((\\w+):(\\w+)@\\w+\\(((?:(?:2(?:5[0-5]|[0-4]\\d))|[0-1]?\\d{1," +
		"2})(?:\\.(?:2(?:5[0-5]|[0-4]\\d)|[0-1]?\\d{1,2})){3}):([0-9]+)\\)/(\\w+).*)\\?")
)
```



mysql link序列化

```go
func DumpsMysqlLink(username, password, host, port, db string) string {
	return fmt.Sprintf(option.MysqlLinkFormat, username,
		password, host, port, db)
}

```

Mysql link 反序列化

```go
func LoadsMysqlLink(link string) (username, password, host, port, db string, err error) {
	dbInfos := option.MysqlLinkRegex.FindStringSubmatch(link)
	if len(dbInfos) != 7 {
		return username, password, host, port, db, fmt.Errorf("illegal mysql link: %s", link)
	}
	return dbInfos[2], dbInfos[3], dbInfos[4], dbInfos[5], dbInfos[6], nil
}

```

