#!/bin/bash
# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# show the commands before execution on stdout and exit on error
set -ex

stop()
{
	echo "----------------------------------------"
	echo "Stopping node MYNODE..."
	mqsistop MYNODE
}

start()
{
	echo "----------------------------------------"
  /opt/ibm/iib-${IIB_VERSION}/iib version
	echo "----------------------------------------"
	echo "----------------------------------------"
	echo "Starting syslog"
  sudo /usr/sbin/rsyslogd
	if [ -z "$MQSI_VERSION" ]; then
  	echo "Sourcing profile"
  	source /opt/ibm/iib-${IIB_VERSION}/server/bin/mqsiprofile
	fi
	if [[ "$GLOBALCACHE" = @(internal|external) ]]; then
		echo "enable embedded global cache"
		mqsichangebroker MYNODE -b default
	fi
	echo "Starting node MYNODE"
	mqsistart MYNODE
	echo "----------------------------------------"
}

config()
{
	echo "----------------------------------------"
  echo "Applying the iib admin inteface config"
  mqsichangefileauth MYNODE -r iibObserver -p read+
  mqsichangefileauth MYNODE -r iibAdmins -p all+
  echo "Create users with role admin and observer"
	. /secret/pw.sh
  mqsiwebuseradmin MYNODE -c -u admin -a $IIBADMINPW -r iibAdmins
  mqsiwebuseradmin MYNODE -c -u observer -a $IIBOBSERVERPW -r iibObserver
  echo "give user permission on the integration server"
  mqsichangefileauth MYNODE -r iibObserver -p read+ -e default
  mqsichangefileauth MYNODE -r iibAdmins -p all+ -e default
  echo "Check file auth"
  mqsireportfileauth MYNODE -l
  echo "Set trace nodes to:" $TRACEMODE
  /opt/ibm/iib-${IIB_VERSION}/server/bin/mqsichangetrace MYNODE -n $TRACEMODE -e default

	# configure a external global cache
	if [ "$GLOBALCACHE" = external ]; then
		echo "configure external globale cache from an IBM Extreme Scale"
		mqsisetdbparms MYNODE  -n wxs::id1 -u $GC_USER -p $GC_PASSWD
		mqsicreateconfigurableservice MYNODE -c WXSServer -o xc10 -n catalogServiceEndPoints,gridName,securityIdentity -v \"$GC_CATALOGENDPOINT\",$GC_GRIDNAME,id1
		mqsichangeproperties MYNODE -o ComIbmJVMManager -e default -n jvmMaxHeapSize -v 1536870912
		echo "restart IBM Integration Bus"
		server/bin/mqsistop MYNODE
		server/bin/mqsistart MYNODE
	fi

  if [ -x /usr/local/bin/customconfig.sh ]; then
		/usr/local/bin/customconfig.sh
	fi

}

deploy()
{
	echo "----------------------------------------"
	echo "Running - deploying application from /iibProjects"
	# do it with an add wget -O /iibProjects/app.bar http://config-host/app.bar && rm app.bar
	echo "importing applications in /iibProjects/*"
	FILES=/iibProjects/*
	for f in $FILES
	do
	  filename=$(basename "$f")
	  filenamewithoutextension=$(basename "$f" | cut -d. -f1)
		ls -ll /iibProperties/
	  if [ ! -f /iibDeployed/$filename ]; then
			if [ -f /iibProperties/$filenamewithoutextension.properties ]; then
				echo "... configure $f  with properties file ..."
				mqsiapplybaroverride -b $f -p ./iibProperties/$filenamewithoutextension.properties -r
			fi
	    echo "... importing $f ..."
	    mqsideploy MYNODE -e default -a $f -m -w 120
	    echo " ... done!"
	  else
	    echo "... NOT importing $f because it has already been deployed to this container"
	    echo "... set REDEPLOY-Environment-Variable to true if you want to redeploy"
	  fi
	done
}

iib-license-check.sh
start
config
deploy
trap stop SIGTERM SIGINT
tail -f /var/log/syslog
