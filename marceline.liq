#!/usr/bin/liquidsoap

set("log.level", 1)
set("log.stdout", true)

%include "config.liq"
db_params = "#{db_host} #{db_port} #{db_user} #{db_name}"

def on_next(m) =
  title = m["dps_title"]
  artist = m["dps_artist"]
  log(label="playback", level=1, "Now playing: #{artist} - #{title}")
end

def fetch_next() =
  result = get_process_output("./db_functions.sh next #{db_params}")
	result = string.split(separator="\|", result)

  sched_id = list.nth(result,0)
  audio_id = list.nth(result,1)
  md5 = list.nth(result,2)
  title = list.nth(result,3)
  artist = list.nth(result,4)
  archive = list.nth(result,5)

  prefix = list.hd(string.split(separator="", md5))

  metadata = "dps_audio_id=#{audio_id},dps_sched_id=#{sched_id},dps_md5=\"#{md5}\",dps_title=\"#{title}\",dps_artist=\"#{artist}\""

	request.create("annotate:#{metadata}:replay_gain:#{archive}/#{prefix}/#{md5}.flac")
end

sustainer = mksafe(smart_crossfade(start_next=5., width=3., conservative=true, high=-10., medium=-20., request.dynamic(fetch_next)))

main = amplify(1., override="replay_gain", sustainer)
main = on_metadata(on_next, main)

if enable_mp3 == true then
	ignore(output.icecast(
  		%mp3(bitrate = 256), 
  		mount = "#{stream_mount}.mp3",
  		host = stream_host, port = stream_port, password = stream_password,
  		url = stream_url, name = stream_name, description = stream_description,
  		main))
end

if enable_flac == true then
	ignore(output.icecast(
  		%ogg(%flac(compression = 7)), 
  		mount = "#{stream_mount}.flac",
  		host = stream_host, port = stream_port, password = stream_password,
  		url = stream_url, name = stream_name, description = stream_description,
  		main))
end

if output_alsa == true then
  ignore(output.alsa(main))
end

if output_jack == true then
  ignore(output.jack(main))
end

if output_pulseaudio == true then
  ignore(output.pulseaudio(client="Marceline", main))
end