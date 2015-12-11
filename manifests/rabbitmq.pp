#
# Class: rjil::rabbitmq
#  This class to manage contrail rabbitmq dependency
#
# == Hiera elements required
#
# rabbitmq::manage_repo: no
#   This parameter to disable apt repo management in rabbitmq module
#
# rabbitmq::admin::enable: no
#   To disable rabbitmqadmin
#   Note: In original contrail installation it is disabled, so starting with
#   disabling it.
#


class rjil::rabbitmq (
  $config_cluster = true,
  $rabbit_admin_user = undef,
  $rabbit_admin_pass = undef,
  $cluster_nodes = sort(values(service_discover_consul('rabbitmq'))),
  $erlang_cookie = 'A_SECRET_COOKIE',
  $cluster_node_type = 'disc',
) {

  rjil::test { 'check_rabbitmq.sh': }
  include ::rabbitmq
  #class {'::rabbitmq': 
  #  config_cluster => $config_cluster,
  #  cluster_nodes => $cluster_nodes,
  #  erlang_cookie => $erlang_cookie,
  #  wipe_db_on_cookie_change => true,
  #  cluster_node_type => $cluster_node_type,
  #}

  rabbitmq_user { $rabbit_admin_user:
    admin    => true,
    password => $rabbit_admin_pass,
  }

  rabbitmq_user_permissions { "${rabbit_admin_user}@/":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

 rjil::test::check { 'rabbitmq':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 5672,
  }

  rjil::jiocloud::consul::service { 'rabbitmq':
    tags          => ['real', 'contrail'],
    port          => 5672,
  }


}
