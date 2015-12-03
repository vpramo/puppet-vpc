require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::glance' do

  let :facts do
    {
      :operatingsystemrelease => '14.04',
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :concat_basedir         => '/tmp'
    }
  end
  let :hiera_data do
    {
      'glance::api::registry_host'                  => '10.1.1.100',
      'glance::api::auth_host'                      => '10.1.1.10',
      'glance::api::keystone_password'              => 'pass',
      'glance::registry::keystone_password'         => 'pass',
      'glance::registry::auth_host'                 => '10.1.1.10',
      'glance::api::mysql_module'                   => '2.3',
      'rjil::glance::backend'                       => 'file',
      'glance::backend::swift::swift_store_user'    => 'swiftuser',
      'glance::backend::swift::swift_store_key'     => 'swiftuser_key',
      'openstack_extras::auth_file::admin_password' => 'pw',
      'rjil::glance::server_name'                   => 'glance.server',
      'rjil::glance::api_localbind_port'            => 19292,
      'rjil::glance::api_public_port'               => 9292,
      'rjil::glance::registry_localbind_port'       => 19191,
      'rjil::glance::registry_public_port'          => 9191,

    }
  end

  context 'with http, File backend' do
    it 'should contain http with file backend' do
      should contain_file('/usr/lib/jiocloud/tests/glance.sh')
      should contain_file('/usr/lib/jiocloud/tests/service_checks/glance-registry.sh')
      should contain_class('rjil::apache')

      should contain_apache__vhost('glance-api').with(
        {
          'servername'      => 'glance.server',
          'serveradmin'     => 'root@localhost',
          'port'            => '9292',
          'ssl'             => false,
          'docroot'         => '/usr/lib/cgi-bin/glance-api',
          'error_log_file'  => 'glance-api.log',
          'access_log_file' => 'glance-api.log',
          'proxy_pass'      => [ { 'path' => '/', 'url' => "http://127.0.0.1:19292/"  } ],
        }
      )

      should contain_apache__vhost('glance-registry').with(
        {
          'servername'      => 'glance.server',
          'serveradmin'     => 'root@localhost',
          'port'            => '9191',
          'ssl'             => false,
          'docroot'         => '/usr/lib/cgi-bin/glance-registry',
          'error_log_file'  => 'glance-registry.log',
          'access_log_file' => 'glance-registry.log',
          'proxy_pass'      => [ { 'path' => '/', 'url' => "http://127.0.0.1:19191/"  } ],
        }
      )

      should contain_class('glance::api').with({
        'registry_host'     => '10.1.1.100',
        'registry_port'     => '9191',
        'auth_host'         => '10.1.1.10',
        'keystone_password' => 'pass',
      })
      should contain_class('glance::registry').with({
        'auth_host'         => '10.1.1.10',
        'keystone_password' => 'pass',
      })
      should contain_class('glance::backend::file')
      ['api', 'registry'].each do |x|
        should contain_rjil__jiocloud__logrotate("glance-#{x}").with_logfile("/var/log/glance/#{x}.log")
      end
    end
  end

  context 'with http, swift backend' do
    let :params do {
      'backend' => 'swift'
    } end
    it 'should contain swift backend' do
      should contain_class('glance::backend::swift')
    end
  end

  context 'with http, cinder backend' do
    let :params do
      {
      'backend' => 'cinder'
      }
    end
    it 'should contain swift backend' do
      should contain_class('glance::backend::cinder')
    end
  end

  context 'with http, rbd backend' do
    before do
      hiera_data.merge!({
        'rjil::ceph::fsid' => '123',
        'rjil::ceph::mon_config::mon_config' => ['127.0.0.1']
      })
      facts.merge!({
        'concat_basedir'   => '/tmp',
      })
    end
    let :params do
      {
        'backend'      => 'rbd',
        'ceph_mon_key' => 'test_ceph_mon_key',
      }
    end
    it 'should contain rbd backend' do
      should contain_class('rjil::ceph')
      should contain_class('rjil::ceph::mon_config')
      should contain_rjil__service_blocker('stmon')
      should contain_ceph__auth('glance_client').with({
        'mon_key'     => 'test_ceph_mon_key',
        'client'      => 'glance',
        'file_owner'  => 'glance',
        'keyring_path'=> '/etc/ceph/keyring.ceph.client.glance',
        'cap'         => 'mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=images"'
      })
      should contain_ceph__conf__clients('glance').with({
        'keyring' => '/etc/ceph/keyring.ceph.client.glance',
      })
    end

  end
end
