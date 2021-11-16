---
title: 使用typora为jekyll编写markdown
key: typora_write_jekyll
layout: article
date: '2019-05-27 19:30:00'
tags: 博客  工具
typora-root-url: ../../iblog

---

### 为什么选择typora?

因为所见即所得, 优雅, 简单.相比jekyll自带的jekyll-admin编写markdown更轻松.

### 缺点是什么?

还是需要结合jekyll-admin使用. 

1. 使用命令行工具进入博客项目文件夹.  然后执行jekyll serve 打开服务
2. 打开 [http://localhost:4000/admin/collections/posts](http://localhost:4000/admin/collections/posts) 新建一篇post
3. 设置好文件名称  标题
4. 最下面的原信息设置好 layout: post  date: 选择现在的日期和时间  categories: 选择好分类多个用空格隔开  
5. 打开typora, 打开项目所在的文件夹, 然后执行下面的设置.

### 需要哪些设置?

1. 菜单进入编辑->图片工具->当插入本地图片时->复制图片到文件夹->然后选择img文件夹

![](https://imgs.zhangbaobao.cn/img/image-20190527194841697.png)

2. 菜单选择 编辑->图片工具->设置图片根目录-> 选择项目文件夹
3. 这样拖动图片进入typora, 或者截图粘贴的时候, 图片路径会是`/img/xxx.png`跟jekyll要求的是一样的.

### 愉快的享受typora带来的便捷吧!

