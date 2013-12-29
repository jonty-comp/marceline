#!/usr/bin/liquidsoap

%include "config.liq"
%include "dps_crossfade.liq"

set("log.level", log_level)
set("log.stdout", true)
log(label="status", level=1, "Marceline starting up")

set("request.metadata_decoders.duration",true)

def psql_cmd(sql) =
  log(label="sql", level=4, sql)
  result = get_process_output("psql -h #{db_host} -p #{db_port} -U #{db_user} -d #{db_name} -qAt -c \"#{sql}\"")
  result = string.replace(pattern="\n", (fun (s) -> ""), result)
  string.split(separator="\|", result)
end

def on_next(m) =
  audio_id = m["dps_audio_id"]
  title = m["dps_title"]

  log(label="playback", level=1, "Now playing: #{title}")

  log(label="log", level=3, "Logging #{audio_id}")
  ignore(psql_cmd("insert into log(location, userid, track_title, track_artist, audioid) select 0, 1, v_audio.title, v_audio.artist, v_audio.id from v_audio where id = #{audio_id};"))
end

def fetch_next() =
  result = psql_cmd("select sustschedule.id, audio.id, md5, title, start_smpl, end_smpl, type, archives.localpath from audio join sustschedule on audio.id = sustschedule.audioid join archives on archive = archives.id order by sustschedule.id ASC LIMIT 1;")

  sched_id = list.nth(result,0)
  audio_id = list.nth(result,1)
  md5 = list.nth(result,2)
  title = list.nth(result,3)
  start = float_of_int(int_of_string(list.nth(result,4))) / 44100.0
  finish = float_of_int(int_of_string(list.nth(result,5))) / 44100.0
  type = list.nth(result,6)
  path = list.nth(result,7)

  log(label="metadata", level=3, "Type: #{type} / Cue in: #{start} / Cue out: #{finish}")

  prefix = list.hd(string.split(separator="", md5))

  metadata = "dps_audio_id=#{audio_id},dps_sched_id=#{sched_id},dps_md5=\"#{md5}\",dps_title=\"#{title}\",dps_type=\"#{type}\""
  log(label="fetch_next", level=2, "Fetched next track: #{title}")

  log(label="sust_pop", level=3, "Removing #{sched_id} from scheduler playlist")
  ignore(psql_cmd("delete from sustschedule where id = #{sched_id};"))

  request.create("annotate:#{metadata}:replay_gain:#{path}/#{prefix}/#{md5}.flac")
end

sustainer = amplify(1., override="replay_gain", eat_blank(length=0.05,request.dynamic(length=next_prebuffer.,fetch_next)))

main = mksafe(dps_crossfade(start_next=5., width=3., high=-5., medium=-20., sustainer))
main = on_metadata(on_next, main)

if enable_mp3 == true then
	ignore(output.icecast(
  		%mp3(bitrate = 256), 
  		mount = "#{stream_mount}.mp3",
  		host = stream_host, port = stream_port, password = stream_password,
  		url = stream_url, name = stream_name, description = stream_description,
  		main))
  log(label="icecast", level=1, "MP3 streaming started: http://#{stream_host}:#{stream_port}/#{stream_mount}.mp3")
end

if enable_flac == true then
	ignore(output.icecast(
  		%ogg(%flac(compression = 7)), 
  		mount = "#{stream_mount}.flac",
  		host = stream_host, port = stream_port, password = stream_password,
  		url = stream_url, name = stream_name, description = stream_description,
  		main))
  log(label="icecast", level=1, "FLAC streaming started: http://#{stream_host}:#{stream_port}/#{stream_mount}.flac")
end

if output_alsa == true then
  ignore(output.alsa(main))
  log(label="alsa", level=1, "ALSA output started")
end

if output_jack == true then
  ignore(output.jack(main))
  log(label="jack", level=1, "JACK output started")
end

if output_pulseaudio == true then
  ignore(output.pulseaudio(client="Marceline", main))
  log(label="pulseaudio", level=1, "PulseAudio output started")
end
