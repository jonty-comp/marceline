#!/bin/bash
psql="psql -h $2 -p $3 -U $4 -d $5 -qAt -c "

action=$1

if [ "$action" == "next" ]
then
	for md5 in "`$psql "select v_audio.id, md5, title, artist, path from v_audio join sustschedule on v_audio.id = sustschedule.audioid order by sustschedule.id ASC LIMIT 1;"`"
	do
		echo $md5
	done
fi
