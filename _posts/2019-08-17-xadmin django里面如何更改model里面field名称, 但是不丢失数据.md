---
title: xadmin django里面如何更改model里面field名称, 但是不丢失数据
key: xadmin_rename_field
layout: article
date: '2019-08-17 12:51:00'
tags: 技术 xadmin
typora-root-url: ../../iblog
---

### Q: django里面如何更改model里面field名称, 但是不丢失数据

### A:

执行`python manage.py makemigrations`之后, 打开迁移文件, 找到相关字段部分. 改为

```python
migrations.RenameField(
            model_name='case',
            old_name='update_user',
            new_name='create_user',
        ),
```

如果除了field名称之外,还有其他修改的话, 比如verbose_name或者max_length修改. 那么先忽略这些修改. 这个迁移文件里只保留rename行为. 然后再执行一次`python manage.py makemigrations` 会再生成一个文件.在里面有AlterField. 

之后执行`python manage.py migrate`即可.

举例:

原先model里只有update_user

```python
 update_user = models.CharField(max_length=100, verbose_name="修改人", null=True)
```

现在需要改成

```python
 create_user = models.CharField(max_length=100, verbose_name="创建人", null=True)
    update_user = models.CharField(max_length=100, verbose_name="修改人", null=True)
```

但是需要将原来`update_user`的数据, 导入到现在`create_user`当中. 也就是我们的逻辑不是加了一个字段`create_user`. 而是, 先把`update_user` rename成`create_user`, 然后再增加字段`update_user`

方法先`python manage.py makemigrations`. 生成的`apps/thehive/migrations/0021_auto_20190725_1921.py`文件里面内容是

```python
migrations.AddField(
            model_name='case',
            name='create_user',
            field=models.CharField(max_length=100, null=True, verbose_name='创建人'),
        ),
 migrations.AlterField(
            model_name='case',
            name='update_user',
            field=models.CharField(max_length=100, null=True, verbose_name='修改人'),
        ),
```

也就是默认行为加字段`create_user`, 改字段`update_user`的`verbose_name`. 

我们需要改成rename操作.

```python
 migrations.RenameField(
            model_name='case',
            old_name='update_user',
            new_name='create_user',

        ),
```

改完之后再执行`python manage.py makemigrations`这样, 就增加了`create_user`更改`verbose_name`的行为 和增加新列`update_user`的行为 

`apps/thehive/migrations/0022_auto_20190725_1925.py`

```
migrations.AddField(
    model_name='case',
    name='update_user',
    field=models.CharField(max_length=100, null=True, verbose_name='修改人'),
),
migrations.AlterField(
    model_name='case',
    name='create_user',
    field=models.CharField(max_length=100, null=True, verbose_name='创建人'),
),
```

之后执行`python manage.py migrate`之后如图. 原来修改人的数据都移动到了创建人里面,新增了修改人字段

![](https://imgs.zhangbaobao.cn/img/20190725193025.png)

原先的保存逻辑修改为

```python
    def save_models(self):
        # 每个model proxy保存的时候讲report_type设置成对应的类型
        obj = self.new_obj
        if not obj.create_user:
            obj.create_user = self.user.username
        obj.update_user = self.user.username
        obj.report_type = "报告A"
        obj.save()
```

### 