---
title: xadmin字段编辑自定义样式select2效果的tags
key: xadmin_tags
layout: article
date: '2019-08-15 11:51:00'
tags: 技术 python
typora-root-url: ../../iblog
---

 [**adminx.py**](https://gist.github.com/CheungChan/46444d4d723f77dae83ad1e72446e1bf#file-adminx-py)

```python
from .widgets import Select2Widget

class RulesetForm(ModelForm):
    tags = SimpleArrayField(CharField(), widget=Select2Widget, required=False)
    
class RulesetAdmin:

    form = RulesetForm
```

[**widgets.py**](https://gist.github.com/CheungChan/46444d4d723f77dae83ad1e72446e1bf#file-widgets-py)

```python
import os

from django import forms
from django.utils.safestring import mark_safe

from common.models import Tags

pwd = os.path.abspath(os.path.dirname(__file__))


class Select2Widget(forms.SelectMultiple):
    # 要处理多选的字段
    array_field_list = ['tags']

    def value_from_datadict(self, data, files, name):
        """
        处理前端是tags[]后端tag
        :param data:
        :param files:
        :param name:
        :return:
        """
        if name in self.array_field_list:
            name += '[]'
        try:
            getter = data.getlist
        except AttributeError:
            getter = data.get
        return getter(name)

    def render(self, name, value, attrs=None, renderer=None):
        '''
        关键方法
        :param name:
        :param value:
        :param attrs:
        :return:
        '''
        # 要注入到页面上的js
        JS = '''
        <script>
            $(function () {
                $('.js-example-basic-multiple').select2();
            });
        </script>
        '''
        output = [JS]
        output.append('<select class="js-example-basic-multiple" name="tags[]" multiple="multiple">')
        tags_list = self.get_tags_list()
        if value is None:
            value = []
        for tag in tags_list:
            if tag in value:
                selected = ' selected="selected"'
            else:
                selected = ''
            output.append(f'<option value="{tag}" {selected}>{tag}</option>')
        output.append('</select>')

        return mark_safe('\n'.join(output))

    def get_tags_list(self):
        tags = Tags.objects.all()
        return [t.name for t in tags]
```

