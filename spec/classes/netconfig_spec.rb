require 'spec_helper'

describe 'rjil::netconfig' do
  it 'should create basic network config' do

    should contain_file('/etc/network/interfaces').with_source('puppet:///modules/rjil/etc_network_interfaces')

    should contain_exec('network_down').with(
      {
        :command     => '/sbin/ifdown -a',
        :refreshonly => true,
      }
    )

    should contain_exec('network_up').with(
      {
        :command     => '/sbin/ifup -a',
        :refreshonly => true,
      }
    )
  end
end
