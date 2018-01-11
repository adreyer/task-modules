#!/opt/puppetlabs/puppet/bin/ruby

require 'puppet'
require 'puppet/agent'
require 'puppet/configurer'
require 'json'

begin
  Puppet.initialize_settings
  agent = Puppet::Agent.new(Puppet::Configurer, (not(Puppet[:onetime])))
  enabled = agent.enable()
  result = { previously_enabled: !enabled }
  puts result.to_json
rescue Exception => e
  result = { _error: {
             msg: "Failed to enable agent: #{e.message}",
             kind: "puppetlabs.certregen/error",
             details: {
               class: e.class.to_s,
               backtrace: e.backtrace } } }
  puts result.to_json
  exit 1
end
