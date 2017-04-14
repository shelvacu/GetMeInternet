# GetMeInternet

Designed to figure out how to get a connection to the internet when using a restricted network such as a public wifi with a webform login required.

Inspired by [iodine](http://code.kryo.se/iodine/) (ip over DNS) and [hans](http://code.gerade.org/hans/) (ip over icmp ping)

http://sites.inka.de/bigred/devel/tcp-tcp.html

## Installation

01. [Install](https://crystal-lang.org/docs/installation/index.html) crystal and shards (although they usually come together)
02. Install the sodium development libraries eg. on arch linux `sudo pacman -S libsodium`
03. Install crystal dependencies

        crystal deps

04. Compile

        shards build

	Debugging version

		shards build -d

	Release version (full compiler optimizations)

		shards build --release

## Usage

First, you must select a Pre-shared Key for use between the client and server. Run `bin/util` to generate a key, then copy the config.yml securely to the other end.

The server `bin/server` currently takes no arguments, and listens on port 5431. The client `bin/client` takes one argument, the ip address of the server.


## Contributing

1. Fork it ( https://github.com/shelvacu/GetMeInternet/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [shelvacu](https://github.com/shelvacu) Shelvacu - creator, maintainer
