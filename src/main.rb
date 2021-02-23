require_relative './gnutella/network'

File.open('settings.json') do |file|
  data = JSON.load(file)
  Network.create_network(data)
  puts 'start'
  Network.servents.first.send(nil, Gnutella::PING)
end
