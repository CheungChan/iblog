---
title: tmux多session管理
key: tmux_multi_session
layout: article
date: '2020-12-16 17:00:00'
tags:  linux
typora-root-url: ../../iblog

---

## 需求

多个用户使用一台服务器上的tmux。可能会出现使用的时候彼此冲突的情况。可以使用tmux多session管理

## 实现

#### 查看所有的session

```bash
tmux ls
# chenzhang: 1 windows (created Wed Dec 16 16:37:21 2020) [178x44]
```

#### 创建新的session

```bash
tmux new -s chenzhang
# 使用ctrl+b d退出后台
tmux new -s kaijie
# 使用ctrl+b d退出后台
```

#### 重命名session(把之前的session重命名为common)

```bash
tmux rename-session -t spider-center common
```

#### 这时候查看所有session

``` bash
tmux ls
# chenzhang: 1 windows (created Wed Dec 16 16:37:21 2020) [178x44]
# common: 2 windows (created Fri Nov 20 16:59:35 2020) [178x44]
# kaijie: 1 windows (created Wed Dec 16 16:38:57 2020) [178x44]
```

#### 进入某一个session

```bash
 tmux a -t chenzhang
```

#### 进入公共的session

```bash
tmux a -t common
```

