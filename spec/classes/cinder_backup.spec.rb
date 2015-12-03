require 'spec_helper'

describe 'rjil::cinder::backup' do

  let :params do
    {
      'ceph_mon_key' => 'foo'
    }
  end

  let :facts do
    {
      'osfamily' => 'Debian',
    }
  end

  context 'with default params' do
    it 'should configure cinder backups' do
      should contain_class('cinder::backup')
      should contain_class('cinder::backup::ceph').with({
        'backup_driver'    => 'cinder.backup.drivers.ceph',
        'backup_ceph_user' => 'cinder-backup',

      })
      should contain_ceph__auth('cinder-backup').with({
        'mon_key'      => 'foo',
        'client'       => 'cinder-backup',
        'file_owner'   => 'cinder',
        'keyring_path' => '/etc/ceph/keyring.ceph.client.cinder_backup',
        'cap'          => 'mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=backups"',
      })
      should contain_ceph__conf__clients('cinder-backup').with({
        'keyring' => '/etc/ceph/keyring.ceph.client.cinder_backup'
      })
      should contain_rjil__jiocloud__logrotate('cinder-backup').with({
        'logdir' => '/var/log/cinder/'
      })
    end
  end

end
