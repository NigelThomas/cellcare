#!/bin/bash

# If SQLSTREAM_JAVA_SECURITY_AUTH_LOGIN_CONFIG exist
if [ ! -z "$SQLSTREAM_JAVA_SECURITY_AUTH_LOGIN_CONFIG" ]
then
   echo "... setting SQLSTREAM_JAVA_SECURITY_AUTH_LOGIN"
   echo "SQLSTREAM_JAVA_SECURITY_AUTH_LOGIN_CONFIG=$SQLSTREAM_JAVA_SECURITY_AUTH_LOGIN_CONFIG" >> /etc/sqlstream/environment
fi

# If SQLSTREAM_JAVA_SECURITY_KRB5_CONF exist
if [ ! -z "$SQLSTREAM_JAVA_SECURITY_KRB5_CONF" ]
then
   echo "... setting SQLSTREAM_JAVA_SECURITY_KRB5_CONF"
   echo "SQLSTREAM_JAVA_SECURITY_KRB5_CONF=$SQLSTREAM_JAVA_SECURITY_KRB5_CONF" >> /etc/sqlstream/environment
fi

# set environment
. /etc/sqlstream/environment

function startsServer() {

    if [ -n "SQLSTREAM_LICENSE_KEY" ]
    then
        echo "... creating license file"
        echo "$SQLSTREAM_LICENSE_KEY" > $SQLSTREAM_HOME/sqlstream.lic
    fi

    echo "starting s-Server"
    /etc/init.d/s-serverd start
    echo "starting webagent"
    /etc/init.d/webagentd start

    # wait until server is ready
    while ! $SQLSTREAM_HOME/bin/serverReady
    do
        sleep 3
    done

    # allow a small extra wait while statup completes
    sleep 3

}

function trigger_script() {
	if [ -r $1 ]
	then
	    echo "... execute $1 configuration script"
	    . $1
	fi
}

sed -i 's/parse.details=false/parse.details=true/g' /var/log/sqlstream/Trace.properties

trigger_script /home/sqlstream/cellcare/pre-server-startup.sh

startsServer

trigger_script /home/sqlstream/cellcare/pre-app-startup.sh

echo "... starting app"
echo " >>>"

cd /home/sqlstream
# run any supplied pipeline modification script
if [ -n "$SQLSTREAM_PIPELINE_MODIFY_SQL" ]
then
    $SQLSTREAM_HOME/bin/sqllineClient --run=$SQLSTREAM_PIPELINE_MODIFY_SQL
fi

echo "... starting schema with $SQLSTREAM_PIPELINE_START_SQL"
$SQLSTREAM_HOME/bin/sqllineClient --run=$SQLSTREAM_PIPELINE_START_SQL

trigger_script /home/sqlstream/cellcare/post-app-startup.sh

tail -F /var/log/sqlstream/Trace.log.0
