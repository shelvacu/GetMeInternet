require "yaml"

module GetMeInternet
  class Config
    YAML.mapping(
      hexkey: {
        type: String,
        nilable: true
      },
      device_name: {
        type: String,
        nilable: true
      }
    )

    getter device_name
    setter device_name
    
    @key : Bytes?

    def self.autoload
      if File.exists? "config.yml"
        conf = GetMeInternet::Config.from_yaml File.read "config.yml"
      else
        conf = GetMeInternet::Config.new
      end
      return conf
    end

    def initialize
    end

    def key
      hexkey.try do |hk|
        return @key unless @key.nil?
        byte_arr = hk.chars.each_slice(2).map(&.join.to_u8(16)).to_a
        slic = Bytes.new(byte_arr.size){|i| byte_arr[i]}
        return @key = slic
      end
    end

    def key!
      tmp = key
      raise "Key was nil, how dare you!" if tmp.nil?
      return tmp
    end

    def key=(val : Bytes)
      @key = nil
      @hexkey = val.hexstring
    end

    def save
      File.open("config.yml","w") do |f|
        YAML.dump(self,f)
      end
    end
  end
end
