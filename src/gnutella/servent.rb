require 'socket'
require 'json'
require_relative 'p2p'
require_relative 'network'

module Gnutella
  class Servent
    MAX_TTL = 15
    attr_accessor :history, :neighbors, :ip_address, :descriptor_id, :port

    def initialize(args)
      @history = []
      @neighbors = args.fetch(:neighbors)
      @ip_address = args.fetch(:ip_address)
      @descriptor_id = args.fetch(:descriptor_id)
      @port = args.fetch(:port)
      # @socket = TCPServer.open(@ip_address, @port)
    end

    def send(data, descriptor)
      p @descriptor_id
      case descriptor
      when PING
        send_ping(data)
      when PONG
        send_pong(data)
      end
    end

    def receive(data, from)
      his = History.new(descriptor_id: data.header.payload_descriptor, payload_descriptor: data.header.payload_descriptor,
                        from: from)
      @history.push(his)
      process_message(data) if data.header.ttl - 1 == 0
    end

    private

    def process_message(data)
      case packet.header.payload_descriptor
      when PING
        recv_ping(data)
      when PONG
        recv_pong(data)
      else
        print('Bad descriptor')
        exit(1)
      end
    end

    def flooding(data)
      @neighbors.each do |neighbor|
        Network.servents.find do |ser|
          ser.descriptor_id == neighbor
        end
               .receive(data, @descriptor_id)
      end
    end

    def trace_back(data)
      next_servent = @history.find do |his|
        his.descriptor_id == data.header.descriptor_id
      end
      @neighbors.find do |neighbor|
        neighbor.descriptor_id == next_servent.from
      end
                .receive(data, @descriptor_id)
    end

    def recv_ping(data)
      if data.header.descriptor_id == @descriptor_id
        send_pong(data)
      else
        send_ping(data)
      end
    end

    def recv_pong(data)
      print(@ip_address) if data.header.descriptor_id == @descriptor_id
    end

    def send_ping(data)
      if data.nil?
        data =
          Packet.new(
            payload: nil,
            header: Header.new(descriptor_id: @descriptor_id, payload_descriptor: PING,
                               ttl: MAX_TTL, hops: 0, payload_length: 0)
          )
      else
        Packet.new(
          payload: nil,
          header: Header.new(descriptor_id: data.header.descriptor_id, payload_descriptor: PONG,
                             ttl: data.header.ttl - 1, hops: data.header.hops + 1, payload_length: 0)
        )
      end
      flooding(data)
    end

    def send_pong(data)
      if data.nil?
        data =
          Packet.new(
            payload: [@ip_address, @port],
            header: Header.new(descriptor_id: @descriptor_id, payload_descriptor: PING,
                               ttl: MAX_TTL, hops: 0, payload: nil)
          )
      else
        data =
          Packet.new(
            payload: data.payload,
            header: Header.new(descriptor_id: data.header.descriptor_id, payload_descriptor: PONG,
                               ttl: MAX_TTL, hops: 0, payload_length: data.header.payload.to_s.length)
          )
        trace_back(data)
      end
    end
  end
end
