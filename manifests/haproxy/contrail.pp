#
# Class: rjil::haproxy::contrail
#    configure haproxy load balanced services for contrail
#
# Note: Contrail original configuration use haproxy even for single node
# configuration.
# Orignal contrail configuration run haproxy on all nodes with same
# configuration, so any node can load balance its requests to all other nodes
# The probleme with this approach is that if haproxy is down on one machine,
# nobody able to connect to that node directly. We might need proper cluster
# manager to cluster them or to move these to hardware load balancer.

class rjil::haproxy::contrail(
  $vip                     = '0.0.0.0',
  $api_server_vip          = undef,
  $api_backend_ips         = sort(values(service_discover_consul('contrail-api'))),
  $discovery_server_vip    = undef,
  $discovery_backend_ips   = sort(values(service_discover_consul('contrail-discovery'))),
  $api_listen_ports        = 8082,
  $api_balancer_ports      = 9100,
  $discovery_listen_ports  = 5998,
  $discovery_balancer_ports= 9110,
  $neutron_server_vip      = undef,
  $neutron_backend_ips     = sort(values(service_discover_consul('neutron','real'))),
  $neutron_listen_ports    = 9696,
  $neutron_balancer_ports  = 9696,
  $min_members             = '3',
) {

 # Add contrail discovery , contrail api tests here
 $endpoint_tests=['contrail-api.sh','contrail-discovery.sh']
 rjil::test{$endpoint_tests:}

  if $api_server_vip {
    $api_vip_orig = $api_server_vip
  } else {
    $api_vip_orig = $vip
  }

  if $discovery_server_vip {
    $discovery_vip_orig = $discovery_server_vip
  } else {
    $discovery_vip_orig = $vip
  }

  if $neutron_server_vip {
    $neutron_vip_orig = $neutron_server_vip
  } else {
    $neutron_vip_orig = $vip
  }

  if size($api_backend_ips) < $min_members or size($discovery_backend_ips) < $min_members {
     $fail= true
  } else {
     $fail= false
  }

  runtime_fail { 'Haproxy_ready':
    fail    => $fail,
    message => "Waiting for ${min_members} contrail API or discovery is not ready",
  }

  rjil::jiocloud::consul::service { 'pre-haproxy':
    check_command => '/bin/true',
    tags => ['real', 'contrail']
  }


  rjil::haproxy_service { 'api':
    vip               => $api_vip_orig,
    listen_ports      => $api_listen_ports,
    balancer_ports    => $api_balancer_ports,
    cluster_addresses => $api_backend_ips,
    require           => Runtime_fail['Haproxy_ready'],
  }

  rjil::haproxy_service { 'discovery':
    vip               => $discovery_vip_orig,
    listen_ports      => $discovery_listen_ports,
    balancer_ports    => $discovery_balancer_ports,
    cluster_addresses => $discovery_backend_ips,
    require           => Runtime_fail['Haproxy_ready'],
  }

  rjil::haproxy_service { 'neutron':
    #vip               => $neutron_vip_orig,
    #listen_ports      => $neutron_listen_ports,
    balancer_ports    => $neutron_balancer_ports,
    cluster_addresses => $neutron_backend_ips,
    require           => Runtime_fail['Haproxy_ready'],
  }
}

