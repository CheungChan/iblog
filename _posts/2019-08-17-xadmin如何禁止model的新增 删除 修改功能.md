---
title: xadmin如何禁止model的新增 删除 修改功能
key: xadmin_readonly
layout: article
date: '2019-08-17 12:51:00'
tags:  xadmin
typora-root-url: ../../iblog
---

### Q: 如何禁止model的新增 删除 修改功能

### A:

在OptionClass里定义属性`remove_permissions`

```python
class MonitorResultAdmin:
    remove_permissions = ('add', 'change', 'delete')

```

### 