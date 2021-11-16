---
title: 使用django-rest-framework保存models数据的时候上传多张图片
key: drf_multi_images
layout: article
date: '2019-08-29 15:35:00'
tags:  python
typora-root-url: ../../iblog
---

使用drf的时候, 保存图片, 可以使用`models.ImageField`, 然后使用表单提交. 但是有的时候一个model对应多张图片. 比方说创建一个作品, 这个作品有7页图片需要保存.

那首先应该建立两张表, 一张works作品表, 一张works_file作品文件表.并在works_file中设置外键关联到作品表. 并且works_file中要有字段保存页码信息,防止混乱.

```python

class Works(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.DO_NOTHING, db_constraint=False)
    title = models.CharField(max_length=200, verbose_name="标题")
 		update_time = models.DateTimeField(verbose_name="更新时间", default=datetime.now)

    class Meta:
        verbose_name = "作品"
        verbose_name_plural = verbose_name
        ordering = ("update_time",)


def upload_to(instance, filename):
    return "/".join(["work_file", f'{datetime.now().strftime("%Y%m%d_%H%M%S")}__{filename}'])


class WorksFile(models.Model):
    id = models.AutoField(primary_key=True)
    work_file = models.FileField(verbose_name="文件", upload_to=upload_to)
    rank_num = models.PositiveIntegerField(verbose_name='序号')
    works = models.ForeignKey(Works, on_delete=models.DO_NOTHING, db_constraint=False, verbose_name="所属作品")
    update_time = models.DateTimeField(verbose_name="更新时间", default=datetime.now)

    class Meta:
        verbose_name = "作品文件"
        ordering = ("rank_num",)

```

然后创建作品的时候,同时多张保存作品图片,可以复写`serializers.py`中的`create`方法

```python

class WorksMeSerializer(serializers.ModelSerializer):
    id = serializers.ReadOnlyField()
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    update_time = serializers.ReadOnlyField()
    works_files = WorksFileSerializer(source='worksfile_set', many=True, read_only=True, label="作品文件")

    class Meta:
        model = Works
        fields = ("id", "user",  "title", 'update_time', "works_files")

    def create(self, validated_data):
        work_files = self.context.get("view").request.FILES
        works = Works.objects.create(**validated_data)
        for i, work_file in enumerate(work_files.getlist("work_files"), start=1):
            WorksFile.objects.create(works=works, work_file=work_file, rank_num=i)
        return works

```

里面通过context取出request来, 再取出所有图片, 并保存.

还有一个问题, ArrayField在前端展示和接受请求的时候会有问题. 所以针对ArrayField可以指定serializer的Field为自定义的Field

`utils.myfield.py`

```python
# -*- coding: utf-8 -*-
__author__ = '陈章'
__date__ = '2019/8/29 12:58'

from rest_framework.fields import Field


class StringArrayField(Field):
    """
    String representation of an array field.
    """

    def to_representation(self, obj):
        # convert list to string
        return ",".join([str(element) for element in obj])

    def to_internal_value(self, data):
        data = data.split(",")  # convert string to list
        return data

```

`serializer.py`

```python
class WorksMeSerializer(serializers.ModelSerializer):
    id = serializers.ReadOnlyField()
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    styles = StringArrayField()
    instruments = StringArrayField()
```

