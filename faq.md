---
layout: toc
title: PgBouncer FAQ
---

# PgBouncer FAQ

## 如何连接到PgBouncer?

PgBouncer就像Postgres server，所以只需简单的指定您的客户端到PgBouncer端口。

## 如何在几个服务器之间均衡的加载查询?

PgBouncer没有内部多主机配置。
可以通过一些额外的工具实现：

1.  DNS循环。在一个DNS名称后面使用几个IP。每次新的连接启动时，PgBouncer都不会查找DNS。
    相反，它缓存所有IP并在内部循环。注意：如果一个名称后面有超过8个IP，
    则DNS后端必须支持EDNS0协议。详见README。

2.  使用TCP连接负载均衡器。[LVS](http://www.linuxvirtualserver.org/)或者
    [HAProxy](http://www.haproxy.org/)是较好的选择。
    在PgBouncer方面，最好让 `server_lifetime` 更小，也可以把 `server_round_robin` 打开 - 
    默认情况下，空闲连接由LIFO算法重用，当需要负载均衡时，这可能不太好。

## 如何进行故障转移

PgBouncer没有内部的故障切换主机配置也没有检测。
可以通过一些外部工具实现：

1. DNS重新配置 - 当重新配置DNS名称后的ip时，pgbouncer将重新连接到新服务器。
   这个行为可以通过2个配置参数进行调整- **dns_max_ttl** 调整一个主机名的生命周期，
   和 **dns_zone_check_period** 调整区域SOA查询更改的频率。
   如果区域SOA记录已更改，pgbouncer将重新查询该区域下的所有主机名。

2. 写新的主机名到配置并让PgBouncer重新加载它 - 在控制台发送SIGHUP或使用RELOAD;命令。
   PgBouncer将检测修改后的主机配置并重连接到新的服务器。
   

## PgBouncer如何使用SSL连接?

自版本1.7以来，PgBouncer对TLS有了内建的支持。只需要配置它。

[ 较老PgBouncer版本的回答 ]

使用[Stunnel](https://www.stunnel.org/)。自版本4.27以来，
它在客户端和服务器端都支持PostgreSQL协议。通过设置 `protocol=pgsql` 激活它。

可选的是在连接的两端都使用Stunnel，然后就不需要协议支持了。

## 会话池如何使用预备语句?

在会话池模式，重置查询必须清理老的预备语句。这可以通过
`server_reset_query = DISCARD ALL;` 或至少是 `DEALLOCATE ALL;` 来实现。

## 事务池如何使用预备语句?

要使预备语句在该模式中可用，将需要PgBouncer在内部保持追踪它们。
所以在这种模式下保持使用PgBouncer的唯一方法是在客户端禁用预备语句。

### 在JDBC中禁用预备语句

适合JDBC的方式是添加 `prepareThreshold=0` 参数到连接字符串。

### 在PHP/PDO中禁用预备语句

要禁用服务器端的预备语句，PD0属性 `PDO::ATTR_EMULATE_PREPARES` 必须设置为
`true`。在客户端连接时设置：

    $db = new PDO("dsn", "user", "pass", array(PDO::ATTR_EMULATE_PREPARES => true));

或者稍后设置：

    $db->setAttribute(PDO::ATTR_EMULATE_PREPARES, true);

## 在不删除连接的情况下如何升级PgBouncer?

[ 这不能通过TLS连接完成。]

这和使用 `-R` 开关加载新的PgBouncer进程一样简单，并且配置相同：

    $ pgbouncer -R -d config.ini

`-R` (reboot)开关通过unix套接字让新的进程连接到老进程(dbname=pgbouncer)的控制台，
并发出下列命令：

    SUSPEND;
    SHOW FDS;
    SHUTDOWN;

之后，如果新的进程发现旧进程已经结束了就恢复老的连接的工作。
魔法发生在 `SHOW FDS` 命令期间，该命令传送实际的文件描述符给新的进程。

如果接替工作不能正常进行，那么新的进程会被杀死，老的进程继续工作。

## 如何知道哪个客户端连接在哪个服务器上？

在控制台使用SHOW CLIENTS和SHOW SERVERS视图。

1.  使用 `ptr` 和 `link` 映射本地客户端到服务器的连接。

2.  使用客户端连接的 `addr` 和 `port` 标识来自客户端的TCP连接。

3.  使用 `local_addr` 和 `local_port` 标识到服务器的TCP连接。

### SHOW CLIENTS 中重要字段的概览

addr, port
: 客户端连接的源地址

local_addr, local_port
: 客户端连接的本地端点

ptr
: 此连接的唯一id

link
: 该客户端当前连接到的服务器连接的唯一id

### SHOW SERVERS 中重要字段的概览

addr, port
: pgbouncer连接到的服务器地址

local_addr, local_port
: 连接本地端点

ptr
: 此连接的唯一id

link
: 该服务器当前连接到的客户端连接的唯一id

## PgBouncer应该安装在webserver还是数据库服务器上？

这个要看情况。当使用短的连接，连接设置延迟最小化——在连接可用前TCP需要几个包往返时，
安装在webserver上是好的。当有许多不同的主机（比如webserver）连接，
并且它们的连接可以一起优化时，安装在数据库服务器上是好的。

在webserver和数据库服务器上都安装PgBouncer也是可以的。
唯一不好的一点是每个PgBouncer会给每个查询增加一点延迟。
所以最好是简单测试下是不是值的这样做。

