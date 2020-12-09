#!/bin/bash
#
# Actions after s-Server is started, before app is started
. /etc/sqlstream/environment

mkdir /home/sqlstream/input

$SQLSTREAM_HOME/bin/sqllineClient --run=/home/sqlstream/cellcare/cellcare.sql

# s-Dashboard to use this directory
sudo sed -i '/SDASHBOARD_DIR/ s:/opt.*:/home/sqlstream/cellcare/dashboards:' /etc/default/s-dashboardd

sudo service webagentd start
sudo service streamlabd start
sudo service s-dashboardd start




