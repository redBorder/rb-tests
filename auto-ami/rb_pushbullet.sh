#!/bin/bash

[ -f config/notification.conf ] && source config/notification.conf

if [ $1 = "aws" ] ; then
	TITLE="AWS UPLOADED"
	MSG="Se ha finalizado la importación de la AMI $2"
elif [ $1 = "repo" ] ; then
	TITLE="REPOS UPLOADED"
	MSG="Se han finalizado las subidas a los repositorios de $2"
else
	TITLE="push.sh"
	MSG="push.sh te ha mandado una notificacion"
fi

[ "x$SLACK_URL" != "x" ] && curl $SLACK_URL -d "payload={\"text\": \"$TITLE: $MSG\"}"


