#!/bin/bash
psql="psql -h dps0 -U digiplay_user -d digiplay -qAt -c "

action=$1

if [ "$action" == "next" ]
then
	for md5 in `$psql "select md5 from audio join sustschedule on audio.id = sustschedule.audioid order by sustschedule.id ASC LIMIT 1;"`
	do
		echo "/mnt/dps0-0/audio/${md5:0:1}/$md5.flac"
	done
fi
