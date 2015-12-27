#
# Class: rjil::cassandra
#  This class to manage contrail cassandra dependency. Added parameters here to
#  set appropriate defaults, so that hiera config is not required unless any
#  extra configruation.
#
# == Hiera elements
#
# rjil::cassandra::seeds:
#   An array of all cassandra nodes
#
# rjil::cassandra::cluster_name:
#   Cassandra cluster name
# Default: 'contrail'
#
# rjil::cassandra::thread_stack_size:
#   JVM threadstack size for cassandra in KB.
#   Default value in cassandra module cause cassandra startup to fail, due to
#   low jvm thread stack size,
#   Default: 300
#
# rjil::cassandra::version:
#   Cassandra module doesnt support cassandra version 2.x. Also current contrail
#   implementation uses cassandra 1.2.x, so to provide version to avoid
#   installing latest package version which is 2.x
#
# rjil::cassandra::package_name:
#    Cassandra package name, the package name contains the major versions, so
#    have to set the package name.

class rjil::cassandra (
  $local_ip          = $::ipaddress_eth1,
  $seeds             = values(service_discover_consul('cassandra', 'seed')),
  $seed              = false,
  $cluster_name      = 'contrail',
  $thread_stack_size = 300,
  $version           = '1.2.18-1',
  $package_name      = 'dsc12',
  $db_for_config     = true,
) {

  # if we are the seed, add ourselves to the list
  if $seed == true {
    $seeds_with_self = [$local_ip]
    $tag = 'seed'
  } else {
    if size($seeds) < 1 {
      $fail = true
      # this is just being set so that the cassandra class does not fail to compile
      $seeds_with_self = ['127.0.0.1']
      $tag = 'seed'
    } else {
      $fail = false
      $seeds_with_self = $seeds
      $tag = 'nonseed'
    }
  }

  rjil::test { 'check_cassandra.sh': }
  # make sure that hostname is resolvable or cassandra fails
  host { 'localhost':
    ip           => '127.0.0.1',
    host_aliases => ['localhost.localdomain', $::hostname],
  }

  if $thread_stack_size < 229 {
    fail("JVM Thread stack size (thread_stack_size) must be > 230")
  }

  class {'::cassandra':
    listen_address    => $local_ip,
    seeds             => $seeds_with_self,
    cluster_name      => $cluster_name,
    thread_stack_size => $thread_stack_size,
    version           => $version,
    package_name      => $package_name,
    require           => Host['localhost'],
  }


  if $db_for_config {
    $srv_name = 'cassandra'
  } else {
    $srv_name = "cassandra-${cluster_name}"
  }


  rjil::test::check { "$srv_name":
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 9160,
  }

  rjil::jiocloud::consul::service { "$srv_name":
    port          => 9160,
    tags          => ['real', 'contrail', $tag],
  }

}
