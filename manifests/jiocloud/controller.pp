#
# Class: rjil::jiocloud::controller
#

class rjil::jiocloud::controller(
  $keystone_db_password = "sample_keystone_db_password"
) {

  class { 'mysql::server': }
  class { 'keystone::db::mysql':
    password      => $keystone_db_password,
    allowed_hosts => '%',
  }
  class { 'keystone':
    verbose        => True,
    catalog_type   => 'sql',
    admin_token    => 'random_uuid',
    sql_connection => "mysql://keystone_admin:${keystone_db_password}@localhost/keystone",
  }
}
