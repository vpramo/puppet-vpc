##
# Define: rjil::keystone::default_network
#
# == Purpose: Create one default network named default_network to tenant
#
##

define rjil::keystone::default_network (
  $network_name = "${name}_default_net",
  $subnet_name  = "${name}_default_subnet",
  $cidr         = '192.168.0.0/24',
  $tenant       = $name,
) {

  neutron_network {$network_name:
    ensure      => present,
    tenant_name => $tenant,
  }

  neutron_subnet {$subnet_name:
    ensure       => present,
    cidr         => $cidr,
    network_name => $network_name,
    tenant_name  => $tenant,
  }
}
