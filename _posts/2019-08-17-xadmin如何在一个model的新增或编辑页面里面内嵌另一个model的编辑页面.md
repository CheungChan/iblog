---
title: xadmin如何在一个model的新增或编辑页面里面内嵌另一个model的编辑页面
key: xadmin_inline
layout: article
date: '2019-08-17 12:51:00'
tags: 技术 xadmin
typora-root-url: ../../iblog
---

### Q: 如何在一个model的新增或编辑页面里面内嵌另一个model的编辑页面

### A:

1. 定义一个Inline类
2. 在model的OptionClass里面讲Inline类注入到inlines属性里面

举例:

在IOC这个model里面内嵌了两个一对多的model. IOC和FileAttachment

**xadmin.py**

```python
from .models import Case, Ioc, FileAttachment
class IocInline:
    model = Ioc
    extra = 0

class FileAttachmentInline:
    model = FileAttachment
    extra = 0

class CaseForm(ModelForm):
  # 自定义widgets
    tags = SimpleArrayField(CharField(), widget=Select2Widget, required=False)
    
class CaseAdmin:
    list_display = ["name", "happen_datetime", "TLP", "tags", "len_ioc", "len_file", "update_user", "update_time"]
    search_fields = ["name", "TLP", "tags", "update_user"]
    list_filter = ["name", "happen_datetime", "TLP", "update_user", "update_time"]
    # 因为自定义了widgets 所以设置了form属性
    form = CaseForm

    # 在同一编辑界面,内联IOC编辑
    inlines = [IocInline, FileAttachmentInline]
    list_export = []
```

效果图: 

点击+ 即可新增多个

![](http://img.azhangbaobao.cn/img/20190718132851.png)

