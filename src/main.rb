require_relative './gnutella/network'

File.open('settings.json') do |file|
  data = JSON.load(file)
  Network.create_network(data)
  puts '[INFO] Start simulation'
  Network.servents.first.send(nil, Gnutella::PING, 'e')
end
