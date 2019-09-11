---
title: 通过django框架表CRUD自动对apscheduler管理实现定时动态定时任务
key: django_apscheduler
layout: article
date: '2019-09-11 16:45:00'
tags: 技术 python
typora-root-url: ../../iblog
---

### 需求分析

想实现一个需求, 就是通过django的表来管理定时任务, 建立一张定时任务表, 当表新增一条记录的时候, 自动根据表里字段的配置添加定时任务, 表记录修改的时候修改定时任务, 表记录删除的时候删除定时任务. 并对下一次运行时间, 定时任务创建时间 修改时间等进行跟踪.

简单的说就是让前端来配置任务, 或者通过代码ORM操作来配置任务, 其他的定时任务实现尽量屏蔽掉, 其他人不用关心如何调度之类的.

### 开源方案

网上的开源方案是`django-apscheduler`但是实践之后,  发现了几个问题

第一, 自建的表里信息不全, 如果想扩展自己的, 更改代码的时候很痛苦. 不如自己做一个. 

第二, 只能通过装饰器的方式, 提前将定时任务定义好, 然后项目启动的时候跑起来,无法通过前端传过来的值进行动态添加修改定时任务.如果执行了`scheduler.add_job`但是数据库里面没有, 如果加了数据库记录, 定时任务又没法跑成.

所以后来采用的方案是自己写.

### 自研

#### 第一个问题

遇到的第一个问题是, django使用gunicorn启动的时候, 是prefork了多个进程

 一般情况下, 不同的worker初始化了不同的scheduler, 就会导致任务被多次执行

 如果采用网上的方案, 通过每次启动的时候试图创建tcp监听, 如果创建成功, 再初始化scheduler, 能解决多个scheduler被同时执行的问题. 但是, 如果想通过表操作来动态添加定时任务, 没有启动scheduler的worker进程就会没有scheduler对象, 导致添加失败. 网上使用tcp监听的例子如下:

**views.py** 或者**urls.py** , 只有程序加载的时候执行就行

```python
import socket
from django.http import HttpResponse
import sys


if len(sys.argv) == 2 and sys.argv[1] == 'makemigrations' or sys.argv[1] == 'migrate':
    pass
else:
    # 引入定时任务
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.bind(("127.0.0.1", 47200))
    except socket.error:
        print("!!!scheduler already started, DO NOTHING")
    else:
        from schedule_jobs.all_jobs import scheduler

```

这个问题, 最终的解决方案是, 把初始化apscheduler对象的任务要放在master进程中, 这样prefork的时候, 就不会被初始化多次, 怎么放在master进程中呢? 可以通过把代码写在`wsgi.py`中, 来实现

**wsgi.py**

```python

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'threatbook_xadmin.settings')

application = get_wsgi_application()
# 初始化定时任务, 放在wsgi里, 被gunicorn 的 master 执行完, worker进程再fork, 这样不会fork多份
import pytz
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
from apscheduler.schedulers.background import BackgroundScheduler

jobstores = {
    'sqlite': SQLAlchemyJobStore(url="postgresql://threatbook:threatbook@localhost:5432/threatbook")
}
timez = pytz.timezone('Asia/Shanghai')
scheduler = BackgroundScheduler(jobstores=jobstores, timezone=timez)
scheduler.start()

print('scheduler被master进程开启')
```

#### 第二个问题

然后, 应该确定model表, 记录定时任务的哪些信息.

本着最少字段的原则, 发现需要记录的有任务的id(方便追踪), 触发器的参数(cron触发 date触发 interval触发 以及触发时间, 都可以通过json来让前端传递过来,这样最灵活) 下次执行时间(从apscheduler里取出来,方便前端查看) 执行的函数(可以直接通过字符串来指定) 函数的参数, 再加创建时间 修改时间.

**models.py**

```python
class JobInfo(models.Model):
    func_help_text = f"""
    要定时执行的函数
    格式:
    模块路径:方法名
    示例:
    threatbook_scheduler.tasks:test
    """
    job_id = models.CharField(max_length=100, verbose_name='任务id', default=uuid.uuid4)
    trigger_kwargs = JSONField(verbose_name='触发器及其他参数')
    next_run_time = models.DateTimeField(verbose_name='下次运行时间', null=True)
    func = models.CharField(max_length=100, verbose_name='执行函数', help_text=func_help_text)
   func_args = JSONField(verbose_name='函数执行参数, 传递一个数组')
    create_time = models.DateTimeField(verbose_name="创建时间", auto_now_add=True)
    update_time = models.DateTimeField(verbose_name="修改时间", auto_now=True)

    objects = JobInfoManager()
    default_objects = models.Manager()

    class Meta:
        verbose_name = '定时任务'
        verbose_name_plural = verbose_name
        ordering = ('update_time',)

    def get_trigger_kwargs(self):
        return mark_safe(f"<pre>{json.dumps(self.trigger_kwargs)}</pre>")

    get_trigger_kwargs.short_description = '触发器及其他参数'
    def get_func_args(self):
        return mark_safe(f"<pre>{json.dumps(self.func_args, ensure_ascii=False)}</pre>")

    get_func_args.short_description = '函数执行参数'
```

这里有一个坑点, 是如果直接使用models.UUIDField, 貌似最简便, 但是在做filter的时候`JobInfo.objects.filter(job_id=job.id`的时候发现怎么查出来都是空集, 原来uuid类型和字符串类型无法相等, 而且如果用还要做数据库类型(uuid)和python类型(str)之间的类型转换什么的,比较麻烦, 最简单的办法是直接使用`CharField`.

#### 第三个问题

在进行新增记录, 修改记录, 删除记录的时候, 应该自动将定时任务做相应的添加 修改 删除操作.

所以可以直接复写model类的`save delete`方法. 一开始考虑的是用信号来解决. 注册接收`post_save`和`post_delete`信号来实现. 后来发现这里修改的部分, 每一次调用`save`方法都会触发信号函数, 信号函数里面还有save, 又会触发, 导致触发次数过多. 所以最后采用的覆盖默认实例方法来实现.

**models.py**

```python

class JobInfo(models.Model):
    func_help_text = f"""
    要定时执行的函数
    格式:
    模块路径:方法名
    示例:
    threatbook_scheduler.tasks:test
    """
    job_id = models.CharField(max_length=100, verbose_name='任务id', default=uuid.uuid4)
    trigger_kwargs = JSONField(verbose_name='触发器及其他参数')
    next_run_time = models.DateTimeField(verbose_name='下次运行时间', null=True)
    func = models.CharField(max_length=100, verbose_name='执行函数', help_text=func_help_text)
   func_args = JSONField(verbose_name='函数执行参数, 传递一个数组')
    create_time = models.DateTimeField(verbose_name="创建时间", auto_now_add=True)
    update_time = models.DateTimeField(verbose_name="修改时间", auto_now=True)

    objects = JobInfoManager()
    default_objects = models.Manager()

    class Meta:
        verbose_name = '定时任务'
        verbose_name_plural = verbose_name
        ordering = ('update_time',)

    def get_trigger_kwargs(self):
        return mark_safe(f"<pre>{json.dumps(self.trigger_kwargs)}</pre>")

    get_trigger_kwargs.short_description = '触发器及其他参数'
		def get_func_args(self):
        return mark_safe(f"<pre>{json.dumps(self.func_args, ensure_ascii=False)}</pre>")

    get_func_args.short_description = '函数执行参数'
    def save(self, force_insert=False, force_update=False, using=None,
             update_fields=None):
        from threatbook_xadmin.wsgi import scheduler
        old_obj = JobInfo.default_objects.filter(job_id=self.job_id).first()
        if not old_obj:
            # 新增
            try:
                job = scheduler.add_job(self.func, args=self.func_args, id=self.job_id,
                                        **self.trigger_kwargs,
                                        replace_existing=True)
            except LookupError as e:
                logger.exception(e)
                raise LookupError(f"定时任务初始化失败, 不能导入 {self.func}")
            self.next_run_time = job.next_run_time
            super(JobInfo, self).save()
        else:
            # 修改
            if old_obj.func == self.func \
                    and old_obj.func_args == self.func_args \
                    and old_obj.trigger_kwargs == self.trigger_kwargs:
                # next_run_time更新
                super(JobInfo, self).save()
            else:
                scheduler.remove_job(self.job_id)
                try:
                    job = scheduler.add_job(self.func, args=self.func_args, id=self.job_id,
                                            **self.trigger_kwargs,
                                            replace_existing=True)
                except LookupError as e:
                    logger.exception(e)
                    raise LookupError(f"定时任务初始化失败, 不能导入 {self.func}")
                self.next_run_time = job.next_run_time
                super(JobInfo, self).save()

    def delete(self, using=None, keep_parents=False):
        from threatbook_xadmin.wsgi import scheduler
        job_id = self.job_id
        scheduler.remove_job(job_id)
        super(JobInfo, self).delete(using=using, keep_parents=keep_parents)

```

这里, 如果记录不存在,则是新增, 直接添加任务, 添加完取得`next_run_time`信息, 并更新表( 没有用信号的好处,这里可以用super的save直接保存, 如果用了信号, 又会进入信号函数). 

记录存在的话, 修改. 修改的时候, 如果定时信息没有变化,直接调用super的save, 也就是只更改了`next_run_time`. 如果有变化,先删除,再添加

这里又有一个坑点, 我是通过xadmin操作表来debug的. 修改没有问题, 删除的时候, 不进入delete方法. 最终查资料发现, delete是一个action. action里面调用的是`filter_hook`方法`def delete_models(self, queryset): 所以可以在`OptionClass里实现这个方法, 用这个方法遍历再调用models实例的delete方法

**xadmin.py**

```python
import xadmin
from .models import JobInfo


class JobInfoAdmin:
    list_display = ["job_id", "get_trigger_kwargs", "next_run_time", "func", "get_func_args", 'create_time',
                    'update_time']
    exclude = ["next_run_time", "create_time", 'update_time']

    # remove_permissions = ('change',)
    def delete_models(self, queryset):
        for job in queryset:
            job.delete()
        super(JobInfoAdmin, self).delete_models(queryset)


xadmin.site.register(JobInfo, JobInfoAdmin)
```

#### 第四个问题

虽然`apscheduler`使用的是`SQLAlchemyJobStore`, 但是项目重启的时候, 好像不起作用, 表里面没有定时任务数据, 所以应该在一开始, 将models里的定时任务加载到apscheduler, 然后每次查询的时候查询任务状态, 更新`next_run_time`字段信息. 这里每次查询的时候触发, 是表级别的操作, 可以通过自定义manager来解决

**models.py**

```python

global_has_init_apscheduler = False
import logging

logger = logging.getLogger("threatbook_xadmin")


class JobInfoManager(models.Manager):
    def get_queryset(self):
        # 只在第一次的时候将JobInfo表中的任务全部初始化到apscheduler 里面
        global global_has_init_apscheduler
        from threatbook_xadmin.wsgi import scheduler

        if not global_has_init_apscheduler:
            scheduler.remove_all_jobs()
            for job in JobInfo.default_objects.all():
                try:
                    scheduler.add_job(job.func, args=job.func_args, id=job.job_id, **job.trigger_kwargs)
                except LookupError as e:
                    logger.exception(e)
                    raise LookupError(f"定时任务初始化失败, 不能导入 {job.func}")
            print('apscheduler 初始化完成')
            global_has_init_apscheduler = True

        # 更新job状态到JobInfo表
        jobs = scheduler.get_jobs()
        for job in jobs:
            job_info = JobInfo.default_objects.filter(job_id=job.id).first()
            if job_info:
                job_info.next_run_time = job.next_run_time
                job_info.save()

        query_set = JobInfo.default_objects.all()
        return query_set


```

### 最后

这样, 实现了通过操作`JobInfo`这张表就可以操作定时任务. 可以通过xadmin来进行便捷的管理. 

所有任务都放在了**scheduler_jobs.tasks**下

```python
# -*- coding: utf-8 -*-
__author__ = '陈章'
__date__ = '2019/9/10 18:19'
from emails.models import Email


def test(*args):
    print(args)


def send_emails(sender, receivers, subject, content, attachments_path_list):
    print('发送邮件中')
    e = Email(sender=sender, receivers=receivers, subject=subject, content=content,
              attachments_path_list=attachments_path_list)
    e.save()
    print('发送成功')

```



效果图

![](http://img.azhangbaobao.cn/img/20190911175205.png)

![](http://img.azhangbaobao.cn/img/20190911170023.png)

![](http://img.azhangbaobao.cn/img/20190911175516.png)

