---
title: 使用jekyll-admin实现在富文本web编写github pages静态博客
layout: post
---

## 简介
Jekyll对于维护静态html网站和博客非常简单有用，尤其是与GitHub页面一起使用。想知道是否有任何静态网站生成器或CMS，这有助于维护Jekyll网站的实时预览，内联编辑，版面管理，文件管理等。你可以试试jekyll-admin
效果如图

![jekyll-admin](/img/20190510/jekyll-admin.png)


项目链接
[https://github.com/jekyll/jekyll-admin](https://github.com/jekyll/jekyll-admin)

## 安装

编辑GemFile, 最后添加一行
```gem
gem 'jekyll-admin', group: :jekyll_plugins
```

执行
```bash
bundle install
```

## 使用
跟之前一样使用jekyll启动
```bash
bundle exec jekyll serve
```
用浏览器打开  [http://localhost:4000/admin](http://localhost:4000/admin)  即可看到管理页面.