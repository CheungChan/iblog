---
title: xadmin列表页面 顶部 增加自定义按钮 来触发对整个model表的操作
key: xadmin_add_button
layout: article
date: '2019-08-17 12:51:00'
tags: 技术 xadmin
typora-root-url: ../../iblog
---

### Q: xadmin列表页面 顶部 增加自定义按钮 来触发对整个model表的操作

### A:

如果是对单个数据库记录操作, 可以直接显示自定义列解决.

如果是对多行记录触发操作, 可以写`Actions`来解决.

对整个数据库表进行操作, 类似数据导入导出(内置的plugin). 可以通过写plugins解决.

`plugins.py`

```python
from django.template import loader
from xadmin.views import BaseAdminPlugin

class SendHuntingRulesPlugin(BaseAdminPlugin):
    send_hunting_rules = False

    def init_request(self, *args, **kwargs):
        return bool(self.send_hunting_rules)

    def block_top_toolbar(self, context, nodes):
        # 在页面插入html片段, 显示下发启用规则
        nodes.append(loader.render_to_string("hunting/yara_ruleset/send_hunting_rules.html"))
```

```html
<button class="btn btn-success pull-right" id="btn_store_all_rules">下发启用规则</button>
<script>
    $(document).ready(function () {
        $("#btn_store_all_rules").click(function () {
            if (confirm("您确定要下发规则么?")) {
                $.ajax({
                    type: 'post',
                    url: '/api/hunting/send_rules',
                    dataType: 'json',
                    success: function (msg) {

                        alert(msg["info"]);

                    }
                });
            }
        });
    });
</script>
```

`adminx.py`  通过`lookat`显示订阅状态, 通过属性`send_hunting_rules`来加载插件.

```python
from .plugins import SendHuntingRulesPlugin

class YaraRulesetAdmin:
    list_display = ["name", "source", "create_user", "update_user", "update_time", "vt_status", "status", "lookat"]
    
    # 通过插件显示下发启用规则
    send_hunting_rules = True

    def lookat(self, model):
        return "已订阅" if self.user.username in model.lookup_users else "未订阅"

    lookat.short_description = "订阅状态"
 
# 最后别忘了注册插件
xadmin.site.register_plugin(SendHuntingRulesPlugin, ListAdminView)
```

然后自定义视图来处理业务逻辑即可.

效果图:

![](https://imgs.zhangbaobao.cn/img/20190809163420.png)