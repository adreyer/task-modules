#!/opt/puppetlabs/puppet/bin/ruby
#
require 'json'
require 'puppet'
require 'puppet/ssl/certificate_authority'


host = 'unknown_host'
signed = false

begin
  if ARGV[0]
    params = ARGV[0]
  else
    params = STDIN.read
  end
  params = JSON.parse(params)
  host =  params['host'] || 'alex-agent1.slice.puppetlabs.net'
  fingerprint = params['fingerprint']
  signing_options = {}
  [:allow_authorization_extensions, :allow_dns_alt_names]
  signing_options[:allow_authorization_extensions] = params['allow_authorization_extensions'] || true
  signing_options[:allow_dns_alt_names] = params['allow_dns_alt_names'] || true

  Puppet.initialize_settings
  Puppet::SSL::Oids.register_puppet_oids
  Puppet::SSL::Oids.load_custom_oid_file(Puppet[:trusted_oid_mapping_file])

  Puppet::SSL::Host.ca_location = :only

  ca = Puppet::SSL::CertificateAuthority.new
  req = Puppet::SSL::CertificateRequest.indirection.find(host)
  if ca.list().include?(host)
    # TODO: verify the correct cert was signed
  elsif req
    if fingerprint and req.fingerprint != fingerprint
      raise "Fingerprint of request does not match provided fingerprint"
    end

    ca.sign(host, signing_options)
    signed = true
  else
    # TODO there is still a race where this will be an arugment error
    raise "Could not find certificate request for host"
  end

  result = { signed: signed }
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
