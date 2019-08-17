---
title: xadmin如何使用一个数据库表, 但是使用多个xadmin页面
key: xadmin_proxy
layout: article
date: '2019-07-18 12:51:00'
tags: 技术 xadmin
typora-root-url: ../../iblog
---

### Q: 如何使用一个数据库表, 但是使用多个xadmin页面

### A:

1. 搞清楚为什么有这样的需求, 原因是django的权限系统只能针对表级别的增删改查做. 但是实际开发中, 会出现一种需求, 都是一个model表, 但是里面有个类型字段不同, 操作的权限因而不同. 这就需要五个页面. 但是每个页面的查询实际上是model查询根据类型过滤之后的结果
2. django的model里面有个model proxy. 可以实现这一需求, model proxy不落实到数据库, 但是继承落实到数据库里的model. 实际上增删改查操作继承的model
3. 每个model proxy再定义自己的OptionClass
4. 将model proxy和 OptionClass注册到xadmin
5. 做makemigrations的时候django<2.2的时候有个bug. 就是model proxy生成的权限的Content Type不是model proxy, 而是继承的model的. 需要编写自定义command来修复这个bug.

举例:

```python
from .models import Case



## 定义了5个model proxy
class TuanHuoFenXi(Case):
    class Meta:
        proxy = True
        verbose_name = "报告A类"
        verbose_name_plural = verbose_name
        default_permissions = ('add', 'change', 'delete', 'view')


class AnYuan(Case):
    class Meta:
        proxy = True
        verbose_name = "报告B类"
        verbose_name_plural = verbose_name
        default_permissions = ('add', 'change', 'delete', 'view')


class KeHuYingJiXiangYing(Case):
    class Meta:
        proxy = True
        verbose_name = "报告C类"
        verbose_name_plural = verbose_name
        default_permissions = ('add', 'change', 'delete', 'view')


class QuzhengJiChuzhijianyi(Case):
    class Meta:
        proxy = True
        verbose_name = "报告D类(某人专用)"
        verbose_name_plural = verbose_name
        default_permissions = ('add', 'change', 'delete', 'view')


class Notes(Case):
    class Meta:
        proxy = True
        verbose_name = "报告E类"
        verbose_name_plural = verbose_name
        default_permissions = ('add', 'change', 'delete', 'view')


# 5个OptionClass的共同基类, 因为展示字段 搜索字段 过滤字段 内联字段等有很多相同的部分
class BaseAdmin:
    list_display = ["name", "happen_datetime", "TLP", "tags", "len_ioc", "len_file", "update_user", "update_time"]
    search_fields = ["name", "TLP", "tags", "update_user"]
    list_filter = ["name", "happen_datetime", "TLP", "update_user", "update_time"]
    form = CaseForm

    # 在同一编辑界面,内联IOC编辑
    inlines = [IocInline, FileAttachmentInline]
    # 禁用导出功能
    list_export = []


class CaseAdmin(BaseAdmin):
    # 编辑时不显示某些字段
    exclude = ["report_type", "is_tdps", "update_user", "related_address", "related_consumer", "clue_source"]

    def save_models(self):
        # 每个model proxy保存的时候讲report_type设置成对应的类型
        obj = self.new_obj
        obj.update_user = self.user.username
        obj.report_type = "报告A类"
        obj.save()

    def queryset(self):
        # 列表只展示report_type为对应的类型的结果集
        return self.model.objects.filter(report_type="报告A类")


class AnYuanAdmin(BaseAdmin):
    exclude = ["report_type", "is_tdps", "update_user", "related_consumer", "clue_source"]

    def save_models(self):
        obj = self.new_obj
        obj.update_user = self.user.username
        obj.report_type = "报告B类"
        obj.save()

    def queryset(self):
        return self.model.objects.filter(report_type="报告B类")


class KeHuYingJiXiangYingAdmin(BaseAdmin):
    exclude = ["report_type", "is_tdps", "update_user", "related_address", "clue_source"]

    def save_models(self):
        obj = self.new_obj
        obj.update_user = self.user.username
        obj.report_type = "报告C类"
        obj.save()

    def queryset(self):
        return self.model.objects.filter(report_type="报告C类")


class QuzhengJiChuzhijianyiAdmin(BaseAdmin):
    exclude = ["report_type", "update_user", "related_address", "clue_source"]
    list_filter = ["name", "happen_datetime", "is_tdps", "TLP", "update_user", "update_time"]

    def save_models(self):
        obj = self.new_obj
        obj.update_user = self.user.username
        obj.report_type = "报告D类"
        obj.save()

    def queryset(self):
        return self.model.objects.filter(report_type="报告D类")


class NotesAdmin(BaseAdmin):
    list_display = ["name", "happen_datetime", "clue_source", "len_ioc", "len_file", "update_user", "update_time"]
    search_fields = ["name", "happen_datetime", "clue_source", "update_user"]
    list_filter = ["name", "happen_datetime", "update_user", "update_time"]
    exclude = ["report_type", "is_tdps", "update_user", "related_address", "related_consumer", "threat_level", "tags",
               "TLP"]

    def save_models(self):
        obj = self.new_obj
        obj.update_user = self.user.username
        obj.report_type = "报告E类"
        obj.save()

    def queryset(self):
        return self.model.objects.filter(report_type="报告E类")


# 将5个model proxy和对应的OptionClass注册到xadmin上
xadmin.site.register(TuanHuoFenXi, CaseAdmin)
xadmin.site.register(AnYuan, AnYuanAdmin)
xadmin.site.register(KeHuYingJiXiangYing, KeHuYingJiXiangYingAdmin)
xadmin.site.register(QuzhengJiChuzhijianyi, QuzhengJiChuzhijianyiAdmin)
xadmin.site.register(Notes, NotesAdmin)

```

定义完之后需要执行`python manage.py makemigrations`和`pyhton manage.py migrate` 因为django在2.2版本之前, 有一个bug, model proxy生成的权限的content type是被继承的model, 而不是model proxy导致 赋给用户权限的时候不能正常使用.  但是xadmin目前不支持django 2.2, 最高支持到2.0.12, 所以使用办法在对应app目录下新建一个文件

![](http://img.azhangbaobao.cn/img/20190718172413.png)

**apps/thehive/management/commands/fix_permissions.py**

```python
# -*- coding: utf-8 -*-
__author__ = '陈章'
__date__ = '2019-07-17 18:17'

import sys

from django.contrib.auth.management import _get_all_permissions
from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType
from django.core.management.base import BaseCommand
from django.apps import apps
from django.utils.encoding import smart_text


class Command(BaseCommand):
    help = "Fix permissions for proxy models."

    def handle(self, *args, **options):
        for model in apps.get_models():
            opts = model._meta
            # breakpoint()
            ctype, created = ContentType.objects.get_or_create(
                app_label=opts.app_label,
                model=opts.object_name.lower())

            for codename, name in _get_all_permissions(opts):
                p, created = Permission.objects.get_or_create(
                    codename=codename,
                    content_type=ctype,
                    defaults={'name': name})
                if created:
                    sys.stdout.write('Adding permission {}\n'.format(p))
```

之后执行`python manage.py fix_permissions` 就会把5个model proxy的权限增加到数据库.

但是这里还有一个小坑. 默认增加的权限是增删改, 因为`get_all_permissions(opts)`返回的只有增删改,没有查. 解决办法是在model proxy的class Meta里增加字段`default_permissions = ('add', 'change', 'delete', 'view')`.

**adminx.py**

```python
class QuzhengJiChuzhijianyi(Case):
    class Meta:
        proxy = True
        verbose_name = "报告D类"
        verbose_name_plural = verbose_name
        # 增加default_permissions 覆盖掉django默认的权限只有增删改
        default_permissions = ('add', 'change', 'delete', 'view')
```

执行完`python manage.py makemigrations` `pyhton manage.py migrate` `python manage.py fix_permissions`之后, 即可正常使用了.

效果图:

页面上有5个管理, 实际数据库在一张表里面. 只是report_type字段类型不同

![](http://img.azhangbaobao.cn/img/20190718171613.png)



