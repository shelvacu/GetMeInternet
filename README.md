# GetMeInternet

Designed to figure out how to get a connection to the internet when using a restricted network such as a public wifi with a webform login required.

Inspired by [iodine](http://code.kryo.se/iodine/) (ip over DNS) and [hans](http://code.gerade.org/hans/) (ip over icmp ping)

http://sites.inka.de/bigred/devel/tcp-tcp.html

## Installation

TODO: Write installation instructions here

## Usage

TODO: Write usage instructions here
* prereqs:
  --crystal https://crystal-lang.org/
  --libsodium-dev  (a crypto lib)
  --libxml2-dev
  --libyaml-dev
  --shards (it's like "make")
  --fork the project on github
  --"shards build" to build

* chromium will stop tun0 about 2 seconds after startup
  >> workaround <<: in crosh shell,
   *sudo* the following
    stop shill
    start shill BLACKLISTED_DEVICEDS=tun0
  

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/shelvacu/GetMeInternet/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [shelvacu](https://github.com/shelvacu) Shelvacu - creator, maintainer
