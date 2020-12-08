#!/bin/bash
#
# Actions after s-Server is started, before app is started

$SQLSTREAM_HOME/bin/sqllineClient --run=/home/sqlstream/app/cellcare.sql

service webagentd start
service streamlabd start





