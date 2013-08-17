#!/usr/bin/liquidsoap

%include "config.liq"
db_params = "#{db_host} #{db_port} #{db_user} #{db_name}"

set("log.stdout", true)

def fetch_next() =
  result = get_process_output("./db_functions.sh next #{db_params}")
  print(result)
	result = string.split(separator="\|", result)

  #id = list.nth(result,0)
  md5 = list.nth(result,1)
  #title = list.nth(result,2)
  #artist = list.nth(result,3)
  archive = list.nth(result,4)

  prefix = list.hd(string.split(separator="", md5))

	request.create("replay_gain:#{archive}/#{prefix}/#{md5}.flac")
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