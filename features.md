---
layout: default
title: PgBouncer features
---

# Features

-   Several levels of brutality when rotating connections:

     Session pooling/会话连接池
     :  最礼貌的方法。在客户端连接的时候，在它的连接生命期内，
        会给它赋予一个服务器连接。在客户端断开的时候，服务器连接会放回到连接池中。

     Transaction pooling/事务连接池
     :  仅在事务期间将服务器连接分配给客户端。当PgBouncer注意到该事务结束时，
        服务器将被放回到池中。它打破了应用程序对后端连接的期望。
        只有在应用配合这样的使用模式，没有使用会破坏这种使用模式的时候才能用这个连接方式。
        参阅下表获取会破坏这种模式的特性。

     Statement pooling/语句连接池
     :  最积极的方法。这是一个事务池的一个扭曲的变种——不允许多语句事务。
        这意味着在客户端上强制 "autocommit" 模式，主要针对PL/Proxy。

-   内存需求低（默认是每个连接2K）。这是因为PgBouncer不需要一次性查看所有包。

-   它不绑定到一个后端服务器，目标数据库可以位于不同的主机上。

-   支持在线重新配置大部分设置。

-   支持在线重启/升级，而不用删除客户端连接。

-   仅支持协议V3，所以后端版本必须 \>= 7.4。


## 池模式的SQL特性映射

下面的表列出了各种PostgreSQL特性和它们是否能与PgBouncer池模式一起共用。
请注意， '事务' 池打破了客户端对服务器的期望，
只有在应用程序不使用非工作功能的情况下才能使用。

|----------------------------------+-----------------+---------------------|
| 特性                             |    会话池      |   事务池            |
|----------------------------------+-----------------+---------------------|
| 启动参数                         | 支持 [^0]      | 支持 [^0]           |
| SET/RESET                        | 支持           | 从不支持            |
| LISTEN/NOTIFY                    | 支持           | 从不支持             |
| WITHOUT HOLD CURSOR              | 支持           | 支持                 |
| WITH HOLD CURSOR                 | 支持 [^1]      | 从不支持             |
| 协议级准备计划                   | 支持 [^1]      | 不支持 [^2]          |
| PREPARE / DEALLOCATE             | 支持 [^1]      | 从不支持             |
| ON COMMIT DROP temp tables       | 支持           | 支持                 |
| PRESERVE/DELETE ROWS temp tables | 支持 [^1]      | 从不支持             |
| 重置缓存的计划                   | 支持 [^1]      | 支持 [^1]            |
| LOAD 语句                        | 支持           | 从不支持             |
|----------------------------------+-----------------+---------------------|

[^0]:
    启动参数是: **client_encoding**, **datestyle**, **timezone**
    和 **standard_conforming_strings**.  PgBouncer 可以检测到它们的改动，
    所以它可以保证这些参数对客户端保持一致。自PgBouncer 1.1开始可用。

[^1]:
    完全透明要求 PostgreSQL 8.3 和 PgBouncer 1.1 并设置
    `server_reset_query = DISCARD ALL`.

[^2]:
    有望在PgBouncer中添加对它的支持。

