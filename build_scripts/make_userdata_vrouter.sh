#!/bin/bash -xe

cat <<EOF >userdata_vrouter.txt
#!/bin/bash
date
set -x
release="\$(lsb_release -cs)"
if [ -n "${git_protocol}" ]; then
  export git_protocol="${git_protocol}"
fi
if [ -n "${env_http_proxy}" ]
then
  export http_proxy=${env_http_proxy}
  echo http_proxy="'${env_http_proxy}'" >> /etc/environment
  internal_subnet_exclusion=",${env_subnet}"
  echo 'Acquire::Http::Proxy "${env_http_proxy}";' >> /etc/apt/apt.conf.d/90Proxy
  export no_proxy="127.0.0.1,169.254.169.254,localhost,consul,jiocloudservices.com\${internal_subnet_exclusion}"
  echo no_proxy="'127.0.0.1,169.254.169.254,localhost,consul,jiocloudservices.com\${internal_subnet_exclusion}'" >> /etc/environment
fi
if [ -n "${env_https_proxy}" ]
then
  export https_proxy=${env_https_proxy}
  echo https_proxy="'${env_https_proxy}'" >> /etc/environment
fi
if [ -n "${puppet_vpc_repo_url}" ];then
  if [ -z "\`grep '${puppet_vpc_repo_url}' /etc/apt/sources.list\`" ];then
    echo "deb [arch=amd64] ${puppet_vpc_repo_url} jiocloud main" | tee -a /etc/apt/sources.list
    wget -qO - ${puppet_vpc_repo_url}/repo.key | apt-key add -
  fi
fi
wget -O puppet.deb -t 5 -T 30 http://apt.puppetlabs.com/puppetlabs-release-\${release}.deb
dpkg -i puppet.deb
apt-get update 
apt-get install -y puppet software-properties-common puppet-vpc
mkdir /etc/facter
mkdir /etc/facter/facts.d
if [ -n "${puppet_modules_source_repo}" ]; then
  apt-get install -y git
  git clone ${puppet_modules_source_repo} /tmp/rjil
  if [ -n "${puppet_modules_source_branch}" ]; then
    pushd /tmp/rjil
    git checkout ${puppet_modules_source_branch}
    popd
  fi
  if [ -n "${pull_request_id}" ]; then
    pushd /tmp/rjil
    git fetch origin pull/${pull_request_id}/head:test_${pull_request_id}
    git config user.email "testuser@localhost.com"
    git config user.name "Test User"
    git merge -m 'Merging Pull Request' test_${pull_request_id}
    popd
  fi
  time gem install librarian-puppet-simple --no-ri --no-rdoc;
  mkdir -p /etc/puppet/manifests.overrides
  cp /tmp/rjil/site.pp /etc/puppet/manifests.overrides/
  mkdir -p /etc/puppet/hiera.overrides
  sed  -i "s/  :datadir: \/etc\/puppet\/hiera\/data/  :datadir: \/etc\/puppet\/hiera.overrides\/data/" /tmp/rjil/hiera/hiera.yaml
  cp /tmp/rjil/hiera/hiera.yaml /etc/puppet
  cp -Rf /tmp/rjil/hiera/data /etc/puppet/hiera.overrides
  mkdir -p /etc/puppet/modules.overrides/rjil
  cp -Rf /tmp/rjil/* /etc/puppet/modules.overrides/rjil/
  if [ -n "${module_git_cache}" ]
  then
    cd /etc/puppet/modules.overrides
    wget -O cache.tar.gz "${module_git_cache}"
    tar xzf cache.tar.gz
    time librarian-puppet update --puppetfile=/tmp/rjil/Puppetfile --path=/etc/puppet/modules.overrides
  else
    time librarian-puppet install --puppetfile=/tmp/rjil/Puppetfile --path=/etc/puppet/modules.overrides
  fi
  cat <<INISETTING | puppet apply --config_version='echo settings'
  ini_setting { basemodulepath: path => "/etc/puppet/puppet.conf", section => main, setting => basemodulepath, value => "/etc/puppet/modules.overrides:/etc/puppet/modules" }
  ini_setting { default_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => default_manifest, value => "/etc/puppet/manifests.overrides/site.pp" }
  ini_setting { disable_per_environment_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => disable_per_environment_manifest, value => "true" }
INISETTING
else
  puppet apply --config_version='echo settings' -e "ini_setting { default_manifest: path => \"/etc/puppet/puppet.conf\", section => main, setting => default_manifest, value => \"/etc/puppet/manifests/site.pp\" }"
fi
echo 'env='${env} > /etc/facter/facts.d/env.txt
echo 'cloud_provider='${cloud_provider} > /etc/facter/facts.d/cloud_provider.txt
while true
do
  # first install all packages to make the build as fast as possible
  puppet apply --detailed-exitcodes \`puppet config print default_manifest\` --config_version='echo packages' --tags package
  ret_code_package=\$?
  # now perform base config
  puppet apply --detailed-exitcodes --debug \`puppet config print default_manifest\`
  ret_code_jio=\$?
  if [[ \$ret_code_jio = 1 || \$ret_code_jio = 4 || \$ret_code_jio = 6 || \$ret_code_package = 1 || \$ret_code_package = 4 || \$ret_code_package = 6 ]]
  then
    echo "Puppet failed. Will retry in 5 seconds"
    sleep 5
  else
    break
  fi
done
date
EOF
