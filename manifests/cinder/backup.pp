#
# Class: rjil::cinder
#   Setup openstack cinder.
#
# == Parameters
#
# [*ceph_mon_key,*]
#   Ceph mon key. This is required to generate the keys for additional users.
#
# [*ceph_keyring_file_owner*]
#   The owner of ceph keyring, this file must be readable by cinder user.
#   Default: cinder
#
# [*ceph_keyring_path*]
#   Path to keyring.
#
# [*ceph_keyring_cap*]
#   Ceph caps for the user.
#
# [*ceph_bkp_user*]
#   The user who connect to ceph for backup operations.
#
# [*cinder_bkp_driver*]
#   Ceph caps for the user.
#

class rjil::cinder::backup (
  $ceph_mon_key,
  $ceph_keyring_file_owner = 'cinder',
  $ceph_keyring_bkp_path   = '/etc/ceph/keyring.ceph.client.cinder_backup',
  $ceph_keyring_bkp_cap    = 'mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=backups"',
  $cinder_bkp_user         = 'cinder-backup',
  $cinder_bkp_driver       = 'cinder.backup.drivers.ceph',
) {

  include ::cinder::backup

  class {'::cinder::backup::ceph':
    backup_driver    => $cinder_bkp_driver,
    backup_ceph_user => $cinder_bkp_user,
  }

  ::ceph::auth {'cinder-backup':
    mon_key      => $ceph_mon_key,
    client       => $cinder_bkp_user,
    file_owner   => $ceph_keyring_file_owner,
    keyring_path => $ceph_keyring_bkp_path,
    cap          => $ceph_keyring_bkp_cap,
  }

  ::ceph::conf::clients {'cinder-backup':
    keyring => $ceph_keyring_bkp_path,
  }
  rjil::jiocloud::logrotate { 'cinder-backup':
    logdir => '/var/log/cinder/'
  }

}
