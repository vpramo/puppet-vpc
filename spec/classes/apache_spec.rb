require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::apache' do

  let :facts do
    {
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :osfamily               => 'Debian',
      :lsbdistid              => 'ubuntu',
      :concat_basedir         => '/tmp'
    }
  end

  let :hiera_data do
    {
      'rjil::apache::ssl'  =>  true,
    }
  end

  let :params do
    {
      :ssl_secrets_package_name         => 'jiocloud-ssl-certificate',
      :jiocloud_ssl_cert_package_ensure => 'present',
    }
  end

  context 'with ssl enabled' do
    it do
      should contain_package('jiocloud-ssl-certificate').that_comes_before('Class[apache]')
      should contain_class('apache::mod::ssl')
    end
  end

  context 'with defaults' do
    it do
      should contain_class('apache')
      should contain_class('apache::mod::rewrite')
      should contain_class('apache::mod::proxy')
      should contain_class('apache::mod::proxy_http')
      should contain_class('apache::mod::headers')
      should contain_apache__mod('proxy_wstunnel')
    end
  end
end

