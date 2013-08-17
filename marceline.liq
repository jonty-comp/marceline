#!/usr/bin/liquidsoap

%include "config.liq"

set("log.stdout", true)

def fetch_next() =
	result = list.hd(get_process_lines("./db_functions.sh next"))
	request.create("replay_gain:"^result)
end

sustainer = mksafe(smart_crossfade(start_next=5., width=3., conservative=true, high=-10., medium=-20., request.dynamic(fetch_next)))

main = amplify(1., override="replay_gain", sustainer)

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