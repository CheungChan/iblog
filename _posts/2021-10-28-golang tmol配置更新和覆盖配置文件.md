---
Title: golang toml配置更新和覆盖配置文件
key: goland_toml_update
layout: article
date: '2021-10-28 15:50:00'
tags: 技术 go
typora-root-url: ../../iblog

---
配置更新

```go
	g.Cfg().Set("database.mysql.0.link", dbUrl)
	g.Cfg().Set("database.type", toType)
```



覆盖配置文件

```go
m := g.Cfg().Map()
	buf := new(bytes.Buffer)
	if err := toml.NewEncoder(buf).Encode(m); err != nil {
		glog.Error(err)
	}
	// bak configuration
	gfile.Rename(AppFile, fmt.Sprintf("%s.bak.%s", AppFile, gtime.Now().ISO8601()))
	ioutil.WriteFile(AppFile, buf.Bytes(), 0755)
	glog.Infof("update config success")
```

