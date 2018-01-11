h1. Puppet Cert module

This module contains tasks and plans for managing puppet agent certificates.

h3. Tasks

h4. `puppet_cert::clean`

This task will clean a certificate from the CA

h4. `puppet_cert::renew`

This task will delete the ssl directory on the agent and request a new certificate

h4. `puppet_cert::sign`

This task will sign a certificate request on the CA

h3. Plans

h4. `puppetcert::renew_agent`

This plans will clean, regenerate and sign the certificate for an agent node.
By default it will stop the puppet service during its run and restart puppet
and pxp when complete.
