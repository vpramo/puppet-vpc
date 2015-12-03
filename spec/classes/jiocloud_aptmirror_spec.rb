require 'spec_helper'

describe 'rjil::jiocloud::aptmirror' do

  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystemrelease => '6',
      :concat_basedir         => '/dne',
    }
  end

  it 'should contain default resources' do
    should contain_class('apt_mirror').with_enabled(false)
    should contain_apt_mirror__mirror('ubuntu').with({
      'mirror'     => 'archive.ubuntu.com',
      'os'         => 'ubuntu',
      'release'    => ['trusty', 'trusty-updates', 'trusty-security'],
      'components' => ['main', 'universe', 'restricted', 'multiverse'],
      'source'     => true
    })
    should contain_apt_mirror__mirror('internal').with({
      'mirror'     => 'apt.internal.jiocloud.com',
      'os'         => 'internal',
      'release'    => ['trusty'],
      'components' => ['main'],
      'source'     => false
    })
    should contain_apt_mirror__mirror('rustedhalo').with({
      'mirror'     => 'jiocloud.rustedhalo.com',
      'os'         => 'ubuntu',
      'release'    => ['trusty'],
      'components' => ['main'],
      'source'     => true
    })
    should contain_apt_mirror__mirror('jenkins').with({
      'mirror'     => 'pkg.jenkins-ci.org',
      'os'         => 'debian',
      'release'    => ['binary/'],
      'components' => [],
    })
    should contain_file('/var/spool/apt-mirror/snapshots').with({
      'ensure' => 'directory',
      'owner'  => 'jenkins',
    })
    should contain_file('/var/spool/apt-mirror/snapshots/snapshot.sh').with({
      'owner'  => 'jenkins',
      'mode'   => '0755',
      'source' => 'puppet:///modules/rjil/snapshot.sh',
    })
    should contain_class('apache')
    should contain_apache__vhost('snapshots.internal.jiocloud.com').with({
      'port'    => '80',
      'docroot' => '/var/spool/apt-mirror/snapshots',
    })
    should contain_sudo__conf('jenkins-mirror').with_content(
      "#Managed By Puppet\njenkins ALL=(ALL) NOPASSWD: /usr/bin/apt-mirror /etc/apt/mirror.list"
    )
  end

end
