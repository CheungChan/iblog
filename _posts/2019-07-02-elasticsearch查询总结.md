---
title: elasticsearch查询总结
key: elasticsearch_query
layout: article
date: '2019-07-02 15:20:00'
tags: 技术 数据库
typora-root-url: ../../iblog

---

#### 根据时间范围查询

```bash
GET /domain_ip_log_*/_search
{
  "query": {
    "bool": {
      "filter": {
        "range": {
          "@timestamp": {
            "gte": "2019-07-02T03:30:01.000Z",
            "lte": "2019-07-02T03:30:01.000Z"
          }
        }
      }
    }
  }
}
```

#### 根据指定字段精确查询

```bash
GET /domain_ip_log_*/_search
{
  "query": {
    "bool": {
      "filter": {
        "term": {
          "sourceIP": "10.10.67.25"
        }
      }
    }
  }
}
```

#### 根据指定短语精确查询

根据指定字段精确查询,但是字段是邮箱(含有特殊字符),而字段未按照`string not analyzed`进行索引, 可以进行短语查询



```bash
GET /domain_ip_log_*/_search
{
  "query": {
    "bool": {
      "filter": {
        "match_phrase": {
          "User": "makai@threatbook.cn"
        }
      }
    }
  }
}
```

注意之前

```bash
{
     "match": {
     "User": {
          "query": "makai@threatbook.cn",
          "type": "phrase"
         }
      }
 }
```

这种写法有的时候会遇到问题, 报错`[match] query does not support [type]`, 所以尽量用`match_phrase`这种写法又简洁,又不会报错

#### 同时根据时间范围和短语查询

```bash
GET /domain_ip_log_*/_search
{
  "query": {
    "bool": {
      "filter": {
        "bool": {
          "must": [
            {
              "range": {
                "@timestamp": {
                  "gte": "2019-07-02T03:30:01.000Z",
                  "lte": "2019-07-02T03:30:01.000Z"
                }
              }
            },
            {
              "match": {
                "User": {
                  "query": "makai@threatbook.cn",
                  "type": "phrase"
                }
              }
            }
          ]
        }
      }
    }
  }
}
```

#### 同时根据时间范围和字段精确查询

```bash
GET /domain_ip_log_*/_search
{
  "query": {
    "bool": {
      "filter": {
        "bool": {
          "must": [
            {
              "range": {
                "@timestamp": {
                  "gte": "2019-07-02T03:30:01.000Z",
                  "lte": "2019-07-02T03:30:01.000Z"
                }
              }
            },
            {
              "match_phrase": {
                "User": "makai@threatbook.cn"
              }
            }
          ]
        }
      }
    }
  }
}
```

