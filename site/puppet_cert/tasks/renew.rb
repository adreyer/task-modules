#!/opt/puppetlabs/puppet/bin/ruby

require 'puppet'
require 'fileutils'
require 'yaml'

class Regen

  class Error < RuntimeError
    def initialize(kind, msg, details = nil)
      @kind = kind
      @details = details || {}
      super(msg)
    end

    def result
      { _error: {
        kind: @kind,
        msg: message,
        details: @details } }
    end
  end

  def initialize(params)
    @params = JSON.parse(params)
  end

  def make_request
    setup

    unless @params['fetch_only']
      reset_ssl
      create_attrs
    end

    request_certificate
  end

  def setup
    Puppet.initialize_settings
    Puppet::SSL::Oids.register_puppet_oids
    Puppet.settings.use(:main, :agent, :ssl)
    Puppet::SSL::Host.ca_location = :remote
  end

  def reset_ssl
    @cacert = @params['cacert']
    certpath = Puppet[:localcacert]
    unless @params['trust_ca'] || @cacert
      # TODO: this should just use a fingerprint
      if File.readable?(certpath)
        @cacert = File.open(certpath) { |f| f.read }
      else
        raise Regen::Error.new('puppet_cert/missing_ca',
                               "No ca certificate present at #{certpath} or provided in params")
      end
    end

    FileUtils.rm_rf(Puppet[:ssldir])
    # Let Puppet recreate directories
    Puppet.settings.clear
    Puppet.settings.use(:main, :agent, :ssl)

    if @cacert
      File.open(certpath, 'w') { |f| f.write(@cacert) }
      # TODO: why does this cause a TypeError
      #Puppet::FileSystem.exclusive_create(certpath, 'w') { |f| f.write(cert) }
    end
  end

  def create_attrs
    if attrs = @params['attrs']
      File.open(Puppet[:csr_attributes], 'w') do |f|
        f.write(YAML.dump(attrs))
      end
    end
  end

  def request_certificate(wait = 0)
    host = Puppet::SSL::Host.new
    begin
      host.certificate
    rescue Puppet::Error => e
      raise Error.new('puppet_cert/request-failed',
                      "Certificate request failed: #{e.message}")
    end
    # TODO: handle waiting
    # host.generate
    host
  end
end

begin
  if ARGV[0]
    params = ARGV[0]
  else
    params = STDIN.read
  end

  regen = Regen.new(params)
  host = regen.make_request

  result = { signed: !host.certificate.nil?,
             request_fingerprint: host.certificate_request.fingerprint }
  puts result.to_json
rescue Regen::Error => e
  puts e.result.to_json
  exit 1
rescue StandardError => e
  result = { _error: {
             msg: "Failed to regenerate certificate: #{e.message}",
             kind: "puppetlabs.certregen/regen-failed",
             details: {
               class: e.class.to_s,
               backtrace: e.backtrace } } }
  puts result.to_json
  exit 1
end
