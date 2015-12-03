##
# Define: rjil::keystone::user
#
# == Purpose: create the users, tenants, roles
#
##
define rjil::keystone::user (
  $password,
  $username       = $name,
  $email          = "${name}@jiocloud.local",
  $user_tenant    = $name,
  $create_network = true,
) {

  keystone_tenant { $user_tenant:
    ensure      => present,
    enabled     => true,
  }

  keystone_user { $username:
    ensure   => present,
    enabled  => true,
    email    => $email,
    tenant   => $user_tenant,
    password => $password,
  }

  ##
  # It may be useful to have a default network with subnet created. Another
  # reason to create the networks because we may hit contrail bug 1353325 if we
  # anted to use rjil::neutron::contrail::fip_pool
  ##
  if $create_network {
    rjil::keystone::default_network {$user_tenant: }
  }
}
