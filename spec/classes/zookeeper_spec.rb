require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::zookeeper' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
      :ipaddress       => '10.1.2.3',
    }
  end

  context 'with defaults' do
    it do
      should contain_file('/usr/lib/jiocloud/tests/check_zookeeper.sh')
      should contain_class('zookeeper').with({
        'id' => 3
      })
    end
  end

end
