require 'spec_helper'

describe 'rjil::jiocloud::jenkins' do
  it 'should configure packages' do
    ['openjdk-7-jre-headless',
     'sbuild',
     'ubuntu-dev-tools',
     'python-pip',
     'npm',
     'git',
     'python-lxml',
     'python-dev',
     'autoconf',
     'libtool',
     'haveged',
     'apt-cacher-ng',
     'debhelper',
     'pkg-config',
     'bundler',
     'libxml2-utils',
     'build-essential',
     'libffi-dev',
     'python-virtualenv'].each do |p|
      contain_package(p).with_ensure('installed')
    end
    should contain_class('rjil::jiocloud::jenkins::cloudenvs')
  end

end
