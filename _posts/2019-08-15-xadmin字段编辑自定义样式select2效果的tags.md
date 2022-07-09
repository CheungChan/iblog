---
title: 使用django signal实现报错yara ruleset自动解析保存yara rule
key: xadmin_signals
layout: article
date: '2019-08-15 11:51:00'
tags:  python
typora-root-url: ../../iblog
---

 [**apps.py**](https://gist.github.com/CheungChan/d41b185ec7d376b0c9c2fb71688d2261#file-apps-py)

```python
from django.apps.config import AppConfig


class HuntingConfig(AppConfig):
    name = 'hunting'
    verbose_name = "hunting(开发中)"

    def ready(self):
        import hunting.signals
```

 [**signals.py**](https://gist.github.com/CheungChan/d41b185ec7d376b0c9c2fb71688d2261#file-signals-py)

```python
# -*- coding: utf-8 -*-
__author__ = '陈章'
__date__ = '2019-08-14 15:25'

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import YaraRuleset, YaraRule
from utils.hunting import HuntingUtils
from utils.exceptions import YaraRuleParseException
import logging

logger = logging.getLogger("xxx_xadmin")


@receiver(post_save, sender=YaraRuleset)
def fav_works(sender, instance=None, created=False, **kwargs):
    ruleset_raw_string = instance.ruleset_raw_string
    try:
        rule_list = HuntingUtils.get_rule_list_by_ruleset_s(ruleset_raw_string)
    except YaraRuleParseException as e:
        logger.error(f"yara ruleset 解析错误")
        raise
    for r in rule_list:
        rule_name = r.get("rule_name")
        condition_terms = r.get("condition_terms")
        strings = r.get("strings")
        metadata = r.get("metadata")

        rule_exists = YaraRule.objects.filter(ruleset=instance, name=r.get("rule_name")).all()
        if len(rule_exists) == 0:
            rule = YaraRule(name=rule_name, condition_terms=condition_terms, strings=strings, metadata=metadata,
                            ruleset=instance)
            rule.save()
        else:
            rule_exists = rule_exists[0]
            rule_exists.condition_terms = condition_terms
            rule_exists.strings = strings
            rule_exists.metadata = metadata
            rule_exists.save()


```

[**middlewares.py**](https://gist.github.com/CheungChan/d41b185ec7d376b0c9c2fb71688d2261#file-middlewares-py)

```python
from django.utils.deprecation import MiddlewareMixin
from utils.exceptions import YaraRuleParseException
from django.http import HttpResponse
import stackprinter

class YaraRuleParseMiddleware(MiddlewareMixin):
    def process_exception(self, request, exception):
        if isinstance(exception, YaraRuleParseException):
            html = f"""
             <h1><font color="red">解析yara ruleset报错,请点击浏览器返回按钮重新编辑:</font></h1>
             <h2><font color="red">错误简介:{exception}</font></h2>
             错误详情:
               <pre> {stackprinter.format(exception)}</pre>
             </div>
            """
            return HttpResponse(html, status=400)
        raise exception
```

