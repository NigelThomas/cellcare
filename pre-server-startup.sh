#!/bin/bash
#
# Actions before s-Server is started

echo start Postgres s

service postgresql start

echo install Postgres schema

sudo -u postgres psql -d demo -f /home/sqlstream/app/cellcare.psql




