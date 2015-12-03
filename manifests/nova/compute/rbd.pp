##
# Class: rjil::nova::compute::rbd
#
# Setup ceph configurations for nova compute.
#

class rjil::nova::compute::rbd (
  $ceph_mon_key,
  $cinder_rbd_secret_uuid,
  $ceph_keyring_file_owner    = 'nova',
  $ceph_keyring_path          = '/etc/ceph/keyring.ceph.client.cinder_volume',
  $ceph_keyring_cap           = 'mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images"',
  $rbd_user                   = 'cinder_volume',
) {

  ##
  # Test rbd key is installed to libvirt.
  ##
  class {'rjil::test::compute::rbd':
    cinder_rbd_secret_uuid => $cinder_rbd_secret_uuid,
  }

  ##
  # service blocker to stmon before mon_config to be run.
  # Mon_config must be run on all ceph client nodes also.
  # Also mon_config should be setup before cinder_volume to be started,
  #   as ceph configuration is required cinder_volume to function.
  ##

  ensure_resource('rjil::service_blocker', 'stmon', {})
  Rjil::Service_blocker['stmon']  ->
  Class['rjil::ceph::mon_config'] ->
  Ceph::Conf::Clients['cinder_volume'] ->
  Exec['secret_set_value_cinder_volume']

  ##
  # This will fix the failure on puppet first run.
  ##
  Ceph::Conf::Mon_config<||> ->
  Exec['secret_set_value_cinder_volume']

  Class['::nova'] ->
  Ceph::Auth['cinder_volume']

  Package['libvirt'] ->
  Exec['secret_define_cinder_volume']

  include ::ceph::conf
  include rjil::ceph::mon_config
  include ::nova
  include ::nova::compute
  include ::nova::compute::libvirt

  ##
  # Add ceph keyring for cinder_volume. This is required cinder to connect to
  # ceph.
  ##

  ::ceph::auth {'cinder_volume':
    mon_key      => $ceph_mon_key,
    client       => $rbd_user,
    file_owner   => $ceph_keyring_file_owner,
    keyring_path => $ceph_keyring_path,
    cap          => $ceph_keyring_cap,
  }

  ##
  # Add ceph configuration for cinder_volume. This is required to find keyring
  # path while connecting to ceph as cinder_volume.
  ##
  ::ceph::conf::clients {'cinder_volume':
    keyring => $ceph_keyring_path,
  }


  ##
  # setup virsh secrets for ceph auth
  ##
  exec { "secret_define_cinder_volume":
    command => "echo \"<secret ephemeral='no'
            private='no'><uuid>$cinder_rbd_secret_uuid</uuid><usage
            type='ceph'><name>client.cinder_volume</name></usage></secret>\" | \
            virsh secret-define --file /dev/stdin",
    unless => "virsh secret-list | egrep $cinder_rbd_secret_uuid",
  }

  exec { "secret_set_value_cinder_volume":
    command => "virsh secret-set-value --secret $cinder_rbd_secret_uuid \
                --base64 $(ceph --name mon. --key ${ceph_mon_key} auth get-key \
                client.cinder_volume)",
    unless => "virsh -q secret-get-value $cinder_rbd_secret_uuid | \
             grep \"$(grep ceph --name mon. --key ${ceph_mon_key} auth get-key \
                        client.cinder_volume)\"",
    require => Exec["secret_define_cinder_volume"],
    notify => Service ['libvirt'],
  }

}
