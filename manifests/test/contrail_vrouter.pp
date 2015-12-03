#
# Class: rjil::test::contrail_vrouter
#

class rjil::test::contrail_vrouter (
  $vrouter_interface = 'vhost0',
  $vgw_interface     = 'vgw1',
  $vgw_enabled       = false,
){

  include rjil::test::base

  file { "/usr/lib/jiocloud/tests/contrail_vrouter.sh":
    content => template('rjil/tests/contrail_vrouter.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  if $vgw_enabled {
    file { "/usr/lib/jiocloud/tests/contrail_vgw.sh":
      content => template('rjil/tests/contrail_vgw.sh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }
}
