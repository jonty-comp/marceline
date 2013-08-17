Marceline
=========

*A Liquidsoap-based jukebox script written for [RaW Digiplay] (http://www.github.com/radiowarwick/digiplay/)*

Installation
------------
    sudo apt-get install liquidsoap liquidsoap-plugin-all
*(You don't have to install _all_ the plugins, but you'll need the plugins for the features you're using. Obviously.)*

Edit `config.liq.example` to your needs and save as `config.liq`, then run `marceline.liq`.
Note that you will need to allow passwordless login to the database on whichever computer the script is running on, via the `pg_hba.conf` file.

Roadmap
-------

- Replicate functionality of original sueplay (playing from DB playlist, crossfading, logging)
- Implement fallback solution (static emergency playlist)
- Add automatic takeover when suitable external stream detected
- Migrate to planned REST API instead of direct database access
- Optionally request songs using new HTTP access protocol
