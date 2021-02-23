module Gnutella
  PING = 0x00
  PONG = 0x01

  class Header
    attr_reader :descriptor_id, :payload_descriptor, :ttl, :hops, :payload_length

    def initialize(args)
      @descriptor_id = args.fetch(:descriptor_id),
                       @payload_descriptor = args.fetch(:payload_descriptor),
                       @ttl = args.fetch(:ttl),
                       @hops = args.fetch(:hops),
                       @payload_length = args.fetch(:payload_length)
    end
  end

  class Packet
    attr_reader :header, :payload

    def initialize(args)
      @payload = args.fetch(:payload)
      @header = args.fetch(:header)
    end
  end

  class History
    attr_reader :descriptor_id, :payload_descriptor, :from

    def initialize(args)
      @descriptor_id = args.fetch(:descriptor_id),
                       @payload_descriptor = args.fetch(:payload_descriptor),
                       @from = args.fetch(:from)
    end
  end
end
