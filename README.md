# GetMeInternet

Designed to figure out how to get a connection to the internet when using a restricted network such as a public wifi with a webform login required.

Inspired by [iodine](http://code.kryo.se/iodine/) (ip over DNS) and [hans](http://code.gerade.org/hans/) (ip over icmp ping)

http://sites.inka.de/bigred/devel/tcp-tcp.html

## Installation

01. [Install](https://crystal-lang.org/docs/installation/index.html) crystal and shards (although they usually come together)
02. Install the sodium development libraries
    * for arch linux `sudo pacman -S libsodium`
    * for debian/ubuntu `sudo apt install libsodium-dev`
03. Install crystal dependencies

        crystal deps

04. Compile

		shards build

	Debugging version

		shards build -d

	Release version (full compiler optimizations)

		shards build --release

## Usage

TODO: Write usage instructions here
* prereqs:
  * crystal https://crystal-lang.org/
  * libsodium-dev  (a crypto lib)
  * libxml2-dev
  * libyaml-dev
  * shards (it's like "make")
  * fork the project on github
  * "shards build" to build

* chromium will stop tun0 about 2 seconds after startup
  >> workaround <<: in crosh shell,
   *sudo* the following
    * stop shill
    * start shill BLACKLISTED_DEVICEDS=tun0
  

First, you must select a Pre-shared Key for use between the client and server. 
Run `bin/util` to generate a key, then copy the config.yml securely to the other end.


The server `bin/server` currently takes no arguments, and listens on port 5431. The
client `bin/client` takes one argument, the ip address of the server.

## Security notes

For simplicity and connect time reduction, this program uses symmetric cryptography with a single pre-shared key, of which the client and server both have a copy. This is used for both encrypting and authenticating.

Currently, there is no mechanism in place to prevent replay attacks. Therefor, this software should not yet be considered secure.

Furthermore, no formal review of this code's security has been done, and there likely are more security-related problems that are unknown.

## Contributing

1. Fork it ( https://github.com/shelvacu/GetMeInternet/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Shelvacu](https://github.com/shelvacu) - creator, maintainer
