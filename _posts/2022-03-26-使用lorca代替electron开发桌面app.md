---
Title: 使用lorca代替electron开发桌面app
key: lorca
layout: article
date: '2022-03-26 19:52:00'
tags:  go
typora-root-url: ../../iblog

---



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

