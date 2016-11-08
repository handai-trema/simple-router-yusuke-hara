require 'pio'

# Router network interface
class Interface
  include Pio

  attr_reader :mac_address
  attr_reader :ip_address
  attr_reader :netmask_length
  attr_reader :port_number

  def initialize(options)
    @port_number = options.fetch(:port)
    @mac_address = Mac.new(options.fetch(:mac_address))
    @ip_address = IPv4Address.new(options.fetch(:ip_address))
    @netmask_length = options.fetch(:netmask_length)
  end
end

# List of network interfaces
class Interfaces
  def initialize(interfaces = [])
    @list = interfaces.map do |each|
      Interface.new(each)
    end
  end
  def show()
    str = sprintf("%-5s %-20s %-15s %-10s\n", "port", "mac_address", "ip_address", "netmask")
    @list.each do |each|
      str += sprintf("%-5s %-20s %-15s %-10s\n", each.port_number, each.mac_address, each.ip_address.to_s, each.netmask_length)
    end
    return str
  end

  def find_by(queries)
    queries.inject(@list) do |memo, (attr, value)|
      memo.find_all do |interface|
        interface.__send__(attr) == value
      end
    end.first
  end

  def find_by_prefix(ip_address)
    @list.find do |each|
      netmask_length = each.netmask_length
      each.ip_address.mask(netmask_length) == ip_address.mask(netmask_length)
    end
  end
end
