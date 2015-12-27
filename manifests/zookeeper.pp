#
# Class: rjil::zookeeper
#  This class to manage contrail zookeeper dependency
#
# == Parameters
#
# [*zk_id*]
#    Zookeeper server ID - this is unique integer ID between 1-255, this must be
#    unique for gieven server in zookeeper cluster.
#  Default: automatically generated from its first NIC's IP address
#

class rjil::zookeeper (
  $id            = '1',
  $local_ip      = $::ipaddress,
  $hosts         = service_discover_consul('pre-zookeeper'),
  $leader_port   = 2888,
  $election_port = 3888,
  $seed          = false,
  $min_members   = 3,
  $datastore     = '/var/lib/zookeeper',
) {


  # both of these functions also have hardcoded the use of the 4th octet
  # to determine uniqueness
  #$cluster_array     = join([$zk_id, $leader_port, $election_port],':')
  #$cluster_with_self = zookeeper_cluster_merge_self($cluster_array, $local_ip, $::hostname)

  # forward non-seed failures when there is no leader in their cluster list
  if size($hosts) < $min_members {
    $fail = true
  } else {
    $fail = false
  }

  $zk_cfg    = '/etc/zookeeper/conf'
  $zk_files = File["${zk_cfg}/zoo.cfg", "${zk_cfg}/environment", "${zk_cfg}/log4j.properties", "${zk_cfg}/myid"]

  runtime_fail { 'zk_members_not_ready':
    fail    => $fail,
    message => "Waiting for ${min_members} zk members",
    before  => $zk_files,
  }

  # Add a check that always succeeds that we can use to know
  # when we have enough members ready to configure a cluster.
  rjil::jiocloud::consul::service { 'pre-zookeeper':
    check_command => '/bin/true',
    tags => ['real', $zk_id]
  }

  # the non-seed nodes should not configure themselves until
  # there is at least one active seed node
  if ! $seed {
    $zk_id = regsubst($::hostname, '^vpc-ctrl(\d+)$','\1')+1
    notice($zk_id)
    notice($::hostname)
    #rjil::service_blocker { "zookeeper":
    #  before  => $zk_files,
    #  require => Runtime_fail['zk_members_not_ready']
    #}
  }
  else {
    $zk_id = '1'
  }

  rjil::test::check { 'zookeeper':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 2181,
  }

  rjil::jiocloud::consul::service { 'zookeeper':
    port          => 2181,
    tags          => ['real', 'contrail'],
  }

  class { '::zookeeper':
    id        => $zk_id,
    client_ip => $local_ip,
    servers   => [$hosts['vpc-cfg1']],
    datastore => $datastore,
  }


  rjil::test { 'check_zookeeper.sh': }

}
