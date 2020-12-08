#!/bin/bash
#
# Actions after s-Server is started, before app is started

mkdir /home/sqlstream/input

# $SQLSTREAM_HOME/bin/sqllineClient --run=/home/sqlstream/app/cellcare.sql


service webagentd start
service streamlabd start





