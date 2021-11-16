---
title: xadmin对于ImageField编辑只能重传的bug
key: xadmin_imageField_bug
layout: article
date: '2019-09-16 16:45:00'
tags:  python
typora-root-url: ../../iblog
---

#### 问题

在xadmin中, 对于字段类型是ImageField的, 进入编辑页面, 如果改动其他字段而不理会ImageField字段, 点击保存, 会报错, 图片的字段未上传, 因为必须把图片重新传一遍. 这是xadmin的bug

#### 解决

修改`AdminImageWidget`类, 最后添加一个方法, 最终效果如下:

```python

class AdminImageWidget(forms.FileInput):
    """
    A ImageField Widget that shows its current value if it has one.
    """

    def __init__(self, attrs={}):
        super(AdminImageWidget, self).__init__(attrs)

    def render(self, name, value, attrs=None, renderer=None):
        output = []
        if value and hasattr(value, "url"):
            label = self.attrs.get('label', name)
            output.append(
                '<a href="%s" target="_blank" title="%s" data-gallery="gallery"><img src="%s" class="field_img"/></a><br/>%s ' %
                (value.url, label, value.url, _('Change:')))
        output.append(super(AdminImageWidget, self).render(name, value, attrs, renderer))
        return mark_safe(u''.join(output))

    def use_required_attribute(self, initial):
        return super(AdminImageWidget, self).use_required_attribute(initial) and not initial


```



