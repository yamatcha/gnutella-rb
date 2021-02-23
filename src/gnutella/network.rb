require_relative './p2p'
require_relative './servent'
require 'json'

module Network
  attr_reader :servents

  extend self

  def create_network(settings)
    @@servents = settings.map do |setting|
      Gnutella::Servent.new(descriptor_id: setting['descriptor_id'], ip_address: setting['ip_address'], port: setting['port'],
                            neighbors: setting['neighbors'])
    end
  end

  def servents
    @@servents
  end
end
