---
Title: embed结合gin static 挂载前端静态文件
key: embed_gin_static
layout: article
date: '2022-03-26 19:50:00'
tags:  go
typora-root-url: ../../iblog

---

# embed结合gin static挂载静态文件

当前端打包之后生成一些静态文件，我希望使用go提供的`embed`机制能够将前端文件打包到二进制里面，同时web端访问肯定希望通过gin的staticFS挂载，一举两得。但是如果不至于直接`router.StaticFS("/", http.FS(h5Fs))`会404，需要注意。

```go
package main

import (
	"embed"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/gogf/gf/os/glog"
	"io/fs"
	"net"
	"net/http"
)

//go:embed web/unpackage/dist/build/h5
var h5Fs embed.FS

func main() {
	router := gin.New()
	// 不能直接	router.StaticFS("/", http.FS(h5Fs)) 会有子文件夹路径web/unpackage/dist/build/h5去不掉，
	// 而且embed.FS不是/开头的，而gin的url都是/开头的,怎么都404对不上
	// 要用fs.Sub让embed.FS转换为fs.FS
	webFs, err := fs.Sub(h5Fs, "web/unpackage/dist/build/h5")
	if err != nil {
		glog.Fatal(err)
	}
	router.StaticFS("/", http.FS(webFs))
	ln, _ := net.Listen("tcp", ":0")
	_, port, _ := net.SplitHostPort(ln.Addr().String())
	go func() {
		err := http.Serve(ln, router)
		if err != nil {
			glog.Fatal("ListenAndServe: ", err)
		}
	}()
  url := fmt.Sprintf("http://localhost:%s/index.html", port)
	glog.Infof("打开%s", url)
}

```



冷静分析一下，gin的静态路由无论如何都是`/static`或者`/xxx`都会是`/`开头的，但是`embed`机制要求文件夹1不能是绝对路径也就是不能`/`开头，2不能父路径也就是`../`开头，所以这里是必须要用`fs.Sub`去截取子路径的。

如果挂载的是`//go:embed web/` 那么就要`ebFs, err := fs.Sub(h5Fs, "web")`， 总之`fs.Sub`是不可避免的。
