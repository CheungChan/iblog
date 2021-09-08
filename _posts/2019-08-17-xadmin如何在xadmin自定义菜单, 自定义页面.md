---
title: xadmin如何在xadmin自定义菜单, 自定义页面
key: xadmin_custom_url_page
layout: article
date: '2019-08-17 12:51:00'
tags: 技术 xadmin
typora-root-url: ../../iblog
---

### Q: 如何在xadmin自定义菜单, 自定义页面

### A:

1. 在xadmin.py，GlobalSettings中自定义菜单
2. 自定义视图函数，并获取原来的菜单等信息（主要是为了用xadmin的模板），具体的自己看xadmin源码
3. 在adminx.py中注册路由
4. html继承。

举例:

**xadmin.py:**

```python
class GlobalSetting:
    site_title = 'XX后台管理'
    site_footer = 'XX公司'

    # menu_style = 'accordion' # 设置app折叠
    def get_site_menu(self):
        return (
            {'title': '自定义菜单',
             'menus': (
                 {
                     'title': '自定义页面',
                     'url': '/admin/testview/',
                 },
             )
             },
        )
    # 需要设置权限的话
    # def get_site_menu(self):
    #     return (
    #         {'title': '原来model',
    #          'perm': self.get_model_perm(Case, 'view'),
    #          'menus': (
    #              {
    #                  'title': '新',
    #                  'url': '/admin/test_view2/',
    #                  # 'perm': self.get_model_perm(ZVipbalanceList, 'view'),
    #              },
    #          )
    #          },
    #     )
```

**views.py:**

```python
from xadmin.views import CommAdminView
from django.shortcuts import render


class TestView(CommAdminView):
    def get(self, request):
        context = super().get_context()
        title = "会员延期"
        # context["breadcrumbs"].append({'url': '/cwyadmin/', 'title': title})
        context["title"] = title
        context["context1"] = [1, 2, 3]
        return render(request, 'thehive/test.html', context)  # 主目录的 template下的 html文件
```

**thehive/test.html**



```django

{{ "{%" }} extends 'xadmin/base_site.html' %}
{# 例 展示本地文件内容#}
{{ "{%" }} block nav_form %}
    <h3>{{ "{{" }} title }}</h3>
    {{ "{%" }} for i in context1 %}
        <p>{{ "{{" }} i }}</p>
    {{ "{%" }} endfor %}
{{ "{%" }} endblock %}

```



**xadmin.py:**

```python
import xadmin
from .views import TestView
 
xadmin.site.register_view("testview/", TestView, name="testview")
```

效果图:

![](https://imgs.zhangbaobao.cn/img/20190718172147.png)

### 