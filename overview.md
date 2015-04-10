---
layout: toc
title: PgBouncer overview
---

PgBouncer
=========

Lightweight connection pooler for PostgreSQL.

Features
--------

-   Several levels of brutality when rotating connections:

     Session pooling
      ~ Most polite method. When client connects, a server connection
        will be assigned to it for the whole duration it stays
        connected. When client disconnects, the server connection will
        be put back into pool.

     Transaction pooling
      ~ Server connection is assigned to client only during a
        transaction. When !PgBouncer notices that transaction is over,
        the server will be put back into pool. This is a hack as it
        breaks application expectations of backend connection. You can
        use it only when application cooperates with such usage by not
        using features that can break. See the table below for breaking
        features.

     Statement pooling
      ~ Most aggressive method. This is transaction pooling with a twist
        - multi-statement transactions are disallowed. This is meant to
        enforce "autocommit" mode on client, mostly targeted for
        PL/Proxy.

-   Low memory requirements (2k per connection by default). This is due
    to the fact that !PgBouncer does not need to see full packet at
    once.

-   It is not tied to one backend server, the destination databases can
    reside on different hosts.

-   Supports online reconfiguration for most of the settings.

-   Supports online restart/upgrade without dropping client connections.

-   Supports protocol V3 only, so backend version must be \>= 7.4.

