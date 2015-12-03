#
# Class: rjil::test::compute::rbd
#

class rjil::test::compute::rbd (
  $cinder_rbd_secret_uuid,
) {

  file { "/usr/lib/jiocloud/tests/cinder-secret.sh":
    content => template('rjil/tests/cinder-secret.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
}
