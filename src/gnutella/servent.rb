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

    def send(data, descriptor, option)
      case descriptor
      when PING
        send_ping(data, option)
      when PONG
        send_pong(data)
      end
    end

    def receive(data, from)
      his = History.new(descriptor_id: data.header.descriptor_id, payload_descriptor: data.header.payload_descriptor,
                        from: from)
      return if @history.include?(his)

      @history.push(his)
      process_message(data, from) if data.header.ttl - 1 != 0
    end

    private

    def process_message(data, from)
      case data.header.payload_descriptor
      when PING
        puts "[INFO] #{@descriptor_id} receive ping from #{from}"
        recv_ping(data)
      when PONG
        puts "[INFO] #{@descriptor_id} receive pong from #{from}"
        recv_pong(data)
      else
        print('Bad descriptor')
        exit(1)
      end
    end

    def flooding(data)
      @neighbors.each do |neighbor|
        a = Network.servents.find do |ser|
          ser.descriptor_id == neighbor && ser.descriptor_id && (@history.first.nil? || @history.first.from != ser.descriptor_id)
        end
        a.receive(data, @descriptor_id) unless a.nil?
      end
    end

    def trace_back(data)
      next_servent = @history.find do |his|
        his.descriptor_id == data.header.descriptor_id
      end
      @neighbors.map do |neighbor|
        Network.servents.find do |ser|
          ser.descriptor_id == neighbor
        end
      end
                .find { |ser| ser.descriptor_id == next_servent.from }
                .receive(data, @descriptor_id)
    end

    def recv_ping(data)
      if data.header.descriptor_id == @descriptor_id
        send_pong(data)
      else
        send_ping(data, nil)
      end
    end

    def recv_pong(data)
      if @history.find { |his| his.descriptor_id == data.header.descriptor_id && his.payload_descriptor == PING }.nil?
        puts "[INFO] finish! result is #{data.payload}."
      else
        send_pong(data)
      end
    end

    def send_ping(data, option)
      puts "[INFO] #{@descriptor_id} send ping"
      data = if data.nil?
               Packet.new(
                 payload: nil,
                 header: Header.new(descriptor_id: option, payload_descriptor: PING,
                                    ttl: MAX_TTL, hops: 0, payload_length: 0)
               )
             else
               Packet.new(
                 payload: nil,
                 header: Header.new(descriptor_id: data.header.descriptor_id, payload_descriptor: PING,
                                    ttl: data.header.ttl - 1, hops: data.header.hops + 1, payload_length: 0)
               )
             end
      flooding(data)
    end

    def send_pong(data)
      puts "[INFO] #{@descriptor_id} send pong"
      if data.header.payload_descriptor == PING
        data =
          Packet.new(
            payload: [@ip_address, @port],
            header: Header.new(descriptor_id: @descriptor_id, payload_descriptor: PONG,
                               ttl: MAX_TTL, hops: 0, payload_length: [@ip_address, @port].to_s.length)
          )
        trace_back(data)
      else
        data =
          Packet.new(
            payload: data.payload,
            header: Header.new(descriptor_id: data.header.descriptor_id, payload_descriptor: PONG,
                               ttl: data.header.ttl - 1, hops: data.header.hops + 1, payload_length: data.header.payload_length)
          )
        trace_back(data)
      end
    end
  end
end
