plan puppet_cert::agent_cert(
  String $agent = 'alex-agent2.slice.puppetlabs.net',
  String $caserver = 'dev-master',
  Optional[Hash] $attrs = undef,
  Boolean $trust_ca = false,
  Boolean $manage_pxp_service = true,
) {
  run_task(puppet_cert::disable_agent, $agent, message => "Disabling agent to regenerate its certificate")
  run_task(puppet_cert::clean, $caserver, host => $agent)
  $csr = run_task(puppet_cert::renew, $agent,
    attrs => $attrs,
    trust_ca => $trust_ca).first

  # If the CSR wasn't autosigned sign it by fingerprint and then fetch it on the agent.
  unless($csr['signed']) {
    run_task(puppet_cert::sign, $caserver, 'host' => $agent, 'fingerprint' => $csr['fingerprint'])
    $csr2 = run_task(puppet_cert::renew, $agent, 'fetch_only' => true).first
    unless $csr2['signed'] {
      fail_plan('Certificate for ${agent} was not signed')
    }
  }

  # TODO: this might make sense in a finally but there is a good chance the agent can't run if anything failed anyway.
  run_task(puppet_cert::enable_agent, $agent)
  if $manage_pxp_service {
    run_task(service, [$agent], action => 'restart', name => 'pxp-agent')
  }
}
