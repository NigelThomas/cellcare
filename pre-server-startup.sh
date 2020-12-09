#!/bin/bash
#
# Actions before s-Server is started

echo install Postgres schema

sudo -u postgres psql -d demo -f /home/sqlstream/cellcare/cellcare.psql




