require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::nova::compute::rbd' do

  let :facts do
    {
      :operatingsystem  => 'Debian',
      :osfamily         => 'Debian',
      :concat_basedir   => '/tmp',
      :hostname         => 'node1',
      :ipaddress_vhost0 => '10.1.1.1',
    }
  end

  let :params do
    {
      'ceph_mon_key' => 'secret',
      'cinder_rbd_secret_uuid' => 'secret2'
    }
  end

  let :hiera_data do
    {
      'rjil::ceph::mon_config::mon_config'             => 'foo',
      'nova::network::neutron::neutron_admin_password' => 'pw',
      'ceph::conf::fsid'                               => 'fsid',
    }
  end

  it 'should deploy defaults' do
    should contain_rjil__service_blocker('stmon') \
      .that_comes_before('Class[rjil::ceph::mon_config]') 

    [
      'ceph::conf',
      'rjil::ceph::mon_config',
      'nova',
      'nova::compute',
      'nova::compute::libvirt'
    ].each do |x|
      should contain_class(x)
    end

    should contain_ceph__auth('cinder_volume')

    should contain_ceph__conf__clients('cinder_volume')

    should contain_exec('secret_define_cinder_volume').with({
      :command => "echo \"<secret ephemeral='no'
            private='no'><uuid>secret2</uuid><usage
            type='ceph'><name>client.cinder_volume</name></usage></secret>\" | \
            virsh secret-define --file /dev/stdin",
      :unless => "virsh secret-list | egrep secret2"
    })


  end

end
