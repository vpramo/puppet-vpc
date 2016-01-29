###
## Class: rjil::contrail::ec2api
###

class rjil::contrail::ec2api (
  $db_provision = true,
  $keystone_user_create = false
}{

  if $db_provision {
    include ::mysql::server
    include ::ec2api::db::mysql
    include ::ec2api::db::sync
    Class['::ec2api::db::mysql']->Class['::ec2api::db::sync']->Class['::ec2api']
  }

  if $keystone_user_create {
    include ::ec2api::keystone::auth
  }

  include ::ec2api
}



