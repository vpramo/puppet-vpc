##
# Define: rjil::keystone::tenant
#
# == Purpose: create the users, tenants
#
##
define rjil::keystone::tenant (
  $tenant_name    = $name,
  $enabled        = true,
  $create_network = true,
) {

  keystone_tenant { $tenant_name:
    ensure      => present,
    enabled     => $enabled,
  }


}
