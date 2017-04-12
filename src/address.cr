# Monkey patching stdlib cause fuck the system

class Socket
  struct IPAddress
    def initialize(addr : UInt32, port : UInt16)
      @family = Family::INET
      @addr4 = LibC::InAddr.new(s_addr: addr)
      @size = sizeof(LibC::SockAddrIn)
      @port = port.to_i32
    end
    
    def address_as_u32 : UInt32
      case family
      when Family::INET then return @addr4.s_addr
      else
        raise "Unsupported family for address_as_u32"
      end
    end
  end
end
