---
Title: docker alpine镜像设置时区
key: alphine_tz
layout: article
date: '2022-02-28 19:50:00'
tags:  docker
typora-root-url: ../../iblog

---

## docker alpine镜像设置时区

alpine镜像特别小，只有5M，默认时区是0时区，使用需要修改时区

```dockerfile
RUN apk --update add tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata
```

可以修改基础镜像这样所有其他镜像都会影响到

