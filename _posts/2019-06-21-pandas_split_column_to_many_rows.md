---
title: 使用pandas将一列用分隔符隔开的数据变成多行
key: pandas_split_column_to_many_rows
layout: article
date: '2019-06-21 11:20:00'
tags: 技术 python 数据分析
typora-root-url: ../../iblog

---

### 需求

有一个csv, 是ip和对应的单位名称, ip这一列数据有的是用逗号隔开的, 现在需要将这一的数据拆分成多行, 来应对与其他csv的join操作

原图:

![](https://imgs.zhangbaobao.cn/img/20190621114220.png)



最终结果:



![](https://imgs.zhangbaobao.cn/img/20190621131900.png)



### 解决方案

```python
import pandas as pd

df = pd.read_csv("测试.csv")
"""
把ip单位里面ip用,隔开的变成多行
通过pd.DataFrame(df["ip"].str.split(",").tolist(),index=df["单位"])
把index设成单位, 然后根据ip变成多个columns
未stack前数据结构是
             0        1
单位
北京xxx  1.1.1.1     None
湖南xxx  2.2.2.2  3.3.3.3
广州xxx  4.4.4.4     None
stack之后变成
单位
北京xxx  0    1.1.1.1
湖南xxx  0    2.2.2.2
         1    3.3.3.3
广州xxx  0    4.4.4.4
dtype: object

"""
new_df = pd.DataFrame(df["ip"].str.split(",").tolist(),index=df["单位"]).stack()
"""
现在new_df是2个level的index, 一个是单位,一个是0, 通过reset_index
reset_index把两个level的index都变成column
      单位  level_1        0
0  北京xxx        0  1.1.1.1
1  湖南xxx        0  2.2.2.2
2  湖南xxx        1  3.3.3.3
3  广州xxx        0  4.4.4.4
然后我们只要单位和0这两列
"""
new_df = new_df.reset_index()[["单位",0]]

new_df.columns=["失陷单位","失陷IP"]
"""
最终输出结果
    失陷单位     失陷IP
0  北京xxx  1.1.1.1
1  湖南xxx  2.2.2.2
2  湖南xxx  3.3.3.3
3  广州xxx  4.4.4.4
"""
new_df.to_csv("测试结果.csv",index=False)
```

