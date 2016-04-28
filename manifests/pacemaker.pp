#
# Manifest file for adding pacemaker and corosync
#
class rjil::pacemaker(
  $ipaddress                    = $::ipaddress,
  $enable_secauth               = false,
  $authkey                      = '/etc/corosync/authkey',
  $haproxy_vip_nic              = 'eth1',
  $haproxy_vip_ip               = '192.168.100.29',
  $haproxy_vip_ip_netmask       = '24',
  $haproxy_vip_monitor_interval = '10s',
  $haproxy_monitor_interval     = '3s',
  $stonith_enabled              = false,
  $no_quorum_policy             = 'ignore',
  $resource_stickiness          = 100,
  $debug                        = false,
  $vip_clone_max                = 2,
  $vip_clone_node_max           = 2,
){

  $unicast_addresses = values(service_discover_consul('haproxy', 'global'))

  rjil::test::check { 'pacemaker':
    check_type => 'validation',
    type       => 'pacemaker',
  }

  rjil::test::check { 'corosync':
    check_type => 'validation',
    type       => 'corosync',
  }

  class { 'corosync':
    enable_secauth    => $enable_secauth,
    authkey           => $authkey,
    bind_address      => $ipaddress,
    unicast_addresses => $unicast_addresses,
    quorum_members    => $unicast_addresses,
    debug             => $debug,
  }

  corosync::service { 'pacemaker':
    version => '0',
  }

  cs_property { 'stonith-enabled' :
    value   => $stonith_enabled,
    ensure  => 'present',
  }

  cs_property { 'no-quorum-policy' :
    value   => $no_quorum_policy,
  }

  cs_rsc_defaults { 'resource-stickiness' :
    value => $resource_stickiness,
  }

  cs_primitive { 'haproxy_vip':
    primitive_class => 'ocf',
    primitive_type  => 'IPaddr2',
    provided_by     => 'heartbeat',
    parameters      => { 'ip'             => $haproxy_vip_ip,
                         'cidr_netmask'   => $haproxy_vip_ip_netmask,
                         'nic'            => $haproxy_vip_nic,
                         'clusterip_hash' => 'sourceip',
                       },
    operations      => { 'monitor' => { 'interval' => $haproxy_vip_monitor_interval } },
  }

  cs_primitive { 'haproxy':
    primitive_class => 'ocf',
    primitive_type  => 'haproxy',
    provided_by     => 'heartbeat',
    operations      => { 'monitor' => { 'interval' => $haproxy_monitor_interval } },
  }

  cs_clone { 'haproxy_vip_clone' :
    ensure    => present,
    primitive => 'haproxy_vip',
    clone_max => $vip_clone_max,
    clone_node_max => $vip_clone_node_max,
    globally_unique => true,
    require   => Cs_primitive['haproxy_vip'],
  }

  cs_clone { 'haproxy_clone' :
    ensure    => present,
    primitive => 'haproxy',
    require   => Cs_primitive['haproxy'],
  }

  cs_colocation { 'vip_with_service':
    primitives => [ 'haproxy_vip', 'haproxy' ],
    score     => 'INFINITY',
  }

}
