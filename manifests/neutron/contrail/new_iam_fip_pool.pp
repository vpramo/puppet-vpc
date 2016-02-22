##
# Define rjil::neutron::contrail::new_iam_fip_pool
# == This one is sole responsible for creating route targets for floatingIP Pool.
# Since the change of IAM to Ec2, neutron clients are no longer supported
# Hence calling neutron to create floating IP pool, will fail as it will call neutronclient
# The way forward is to use either curl requests or modify neutron client
# Till this time , in any new environment, we need to manually create the floatingIP pool so that
# the below class will succeed.
# Parameters
# [*public*]
#   This will make the call whether the fip pool to be
##
define rjil::neutron::contrail::new_iam_fip_pool (
  $network_name,
  $subnet_name,
  $cidr,
  $keystone_admin_user,
  $keystone_admin_password,
  $contrail_api_server = 'real.neutron.service.consul',
  $rt_number           = 10000,
  $router_asn          = 64512,
  $subnet_ip_start     = undef,
  $subnet_ip_end       = undef,
  $public              = true,
  $tenant_name         = 'services',
  $tenants             = [],
) {



    contrail_fip_pool {$name:
      ensure         => present,
      network_fqname => "default-domain:${tenant_name}:${network_name}",
      api_server_address => $contrail_api_server,
      tenants        => $tenants,
      admin_user     => $keystone_admin_user,
      admin_password => $keystone_admin_password,
      admin_tenant   => $tenant_name,
    }



  contrail_rt {"default-domain:${tenant_name}:${network_name}:${network_name}":
    ensure             => present,
    rt_number          => $rt_number,
    router_asn         => $router_asn,
    api_server_address => $contrail_api_server,
    admin_tenant       => $tenant_name,
    admin_user         => $keystone_admin_user,
    admin_password     => $keystone_admin_password,
  }


  ##
  # It may need to create different kv for different fip, but just making the logic simple for now.
  ##
  ensure_resource(consul_kv,'neutron/floatingip_pool/status',{ value   => 'ready' })

  Contrail_rt["default-domain:${tenant_name}:${network_name}:${network_name}"] -> Consul_kv['neutron/floatingip_pool/status']

}
