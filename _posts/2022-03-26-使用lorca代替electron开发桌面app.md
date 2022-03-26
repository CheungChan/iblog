---
Title: 使用lorca代替electron开发桌面app
key: lorca
layout: article
date: '2022-03-26 19:52:00'
tags:  go
typora-root-url: ../../iblog

---

electron框架提供了跨平台开发桌面app的能力，缺点是包非常大，非常占内存。过于复杂。对于简单的需求有点杀鸡用牛刀，对于复杂的需求，性能不太行。原因是把chromium浏览器放在了包里。

可以使用lorca来代替。这个框架会寻找本机已经安装的浏览器而不是自己带一个，对于轻量级的应用而是友好。

该框架最大的特点是打出来的包非常小（利用了系统的浏览器），可以在golang里调用js，也可以在js里调用go函数或方法。而且都是异步的。每个golang函数调用都是一个goroutine，对应js里是一个promise。以下是简单的使用案例。

```go
package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/gogf/gf/os/glog"
	"github.com/gogf/gf/os/gproc"
	"github.com/zserge/lorca"
	"io/fs"
	"net"
	"net/http"
)

func main() {
	// url定义
	ui, _ := lorca.New(url, "", 2000, 1000, "--start-maximized", "--ignore-certificate-errors")
	ui.SetBounds(lorca.Bounds{WindowState: lorca.WindowStateMaximized})
	defer ui.Close()

	ui.Bind("call", func(cmd string) string {
		out, err := gproc.ShellExec(cmd)
		if err != nil {
			return err.Error()
		}
		return out
	})
	// Wait for the browser window to be closed
	<-ui.Done()
  
}
```

添加golang方法使用

```go
ui.Bind("call", func(cmd string) string {
   out, err := gproc.ShellExec(cmd)
   if err != nil {
      return err.Error()
   }
   return out
})
```

方法可以在js里直接调用

```js
this.text = await call(this.inputValue);
```

在golang里也可以直接执行js代码

```go
err = ui.Bind("showPageTwo", func() {
		ui.Eval(`document.getElementById("pageTwo").style.display="block";`)
		ui.Eval(`document.getElementById("pageTwo").style.visibility="visible";`)
		ui.Eval(`document.getElementById("pageOne").style.display="none";`)
		ui.Eval(`document.getElementById("pageOne").style.visibility="hidden";`)
	})
	if err != nil {
		log.Fatalf("could not bind showPageTwo %s", err)
		os.Exit(3)
	}
```

