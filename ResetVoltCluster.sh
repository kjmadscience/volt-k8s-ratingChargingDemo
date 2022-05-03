#!/bin/sh
helm uninstall mydb -n voltdb
helm install mydb voltdb/voltdb --values myproperties.yaml --set metrics.enabled=true   --set metrics.delta=true --set cluster.config.deployment.commandlog.enabled=false   --set cluster.config.deployment.snapshot.enabled=false --set-file cluster.config.licenseXMLFile=/Users/thanos/Documents/license.xml -n voltdb
kubectl cp schema/db.sql mydb-voltdb-cluster-0:/tmp/ -n voltdb
kubectl cp schema/voltdb-chargingdemo.jar  mydb-voltdb-cluster-0:/tmp/ -n voltdb

kubectl exec -it mydb-voltdb-cluster-0 -n voltdb -- sqlcmd < schema/db.sql

kubectl create -f usersJob.yaml -n voltdb