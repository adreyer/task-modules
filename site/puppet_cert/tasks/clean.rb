#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'

host = 'unknown_host'

begin
  params = JSON.parse(STDIN.read)
  host =  params['host']

  # setup puppet
  Puppet.initialize_settings
  Puppet::SSL::Host.ca_location = :local

  output = Puppet::SSL::Host.destroy(host)
  result = { _output: output }
  puts result.to_json

rescue StandardError => e
  result = { _error: {
             msg: "Failed to clean certificate for #{host}: #{e.message}",
             kind: "puppetlabs.certregen/clean-failed",
             details: {
               class: e.class.to_s,
               backtrace: e.backtrace } } }
  puts result.to_json
  exit 1
end
