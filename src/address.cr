# Monkey patching stdlib cause fuck the system

class Socket
  struct Address
    def address_as_u32 : UInt32
      case family
      when Family::INET then return @addr4.s_addr
      else
        raise "Unsupported family for address_as_u32"
      end
    end
  end
end
