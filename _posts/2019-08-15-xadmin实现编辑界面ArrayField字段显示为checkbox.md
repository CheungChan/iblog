---
title: xadmin实现编辑界面ArrayField字段显示为checkbox
key: xadmin_checkbox
layout: article
date: '2019-08-15 15:51:00'
tags: 技术 python
typora-root-url: ../../iblog
---

`adminx.py`

```python
from django.forms import ModelForm, CheckboxSelectMultiple, MultipleChoiceField


class YaraRulesetForm(ModelForm):
    scan_file_path_list = MultipleChoiceField(choices=YaraRuleset.SCAN_FILE_PATH_CHOICES, widget=CheckboxSelectMultiple(), label="测试路径")
    
class YaraRulesetAdmin:
    form = YaraRulesetForm
```

显示效果

![](https://imgs.zhangbaobao.cn/img/20190815153244.png)