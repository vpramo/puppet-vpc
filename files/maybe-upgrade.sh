#!/bin/bash

# When we're run from cron, we only have /usr/bin and /bin. That won't cut it.
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Exit codes:
# 0: Yup, there's an update
# 1: No, no updates
# 2: Could not reach consul, so we don't know
# 3: Could not reach consul, but we also haven't been initialised ourselves.
python -m jiocloud.orchestrate pending_update
rv=$?

run_puppet() {
        # ensure that our service catalog hiera data is available
        # now run puppet
        export OS_PROJECT_DOMAIN_NAME='default'
        export OS_USER_DOMAIN_NAME='default'
        export OS_IDENTITY_API_VERSION=3
        host=`hostname`
        if [ $host eq 'keystone1']; then
                export OS_AUTH_URL='https://identity.jiocloud.com:35357/v3/'
        fi
        puppet apply --config_version='python -m jiocloud.orchestrate current_version' --detailed-exitcodes --logdest=syslog `puppet config print default_manifest`
        # publish the results of that run
        ret_code=$?
        python -m jiocloud.orchestrate update_own_status puppet_service $ret_code
        if [[ $ret_code = 1 || $ret_code = 4 || $ret_code = 6 ]]; then
                echo "Puppet failed with return code ${ret_code}, also failing validation"
                python -m jiocloud.orchestrate update_own_status validation_service 1
                sleep 5
                exit 1
        fi
}

validate_service() {
        run-parts --regex=. --verbose --exit-on-error  --report /usr/lib/jiocloud/tests/
        ret_code=$?
        python -m jiocloud.orchestrate update_own_status validation_service $ret_code
        if [[ $ret_code != 0 ]]; then
                echo "Validation failed with return code ${ret_code}"
                sleep 5
                exit 1
        fi
}

if [ $rv -eq 0 ]
then
       pending_version=$(python -m jiocloud.orchestrate current_version)
       echo current_version=$pending_version > /etc/facter/facts.d/current_version.txt
       # Update apt sources to point to new snapshot version
       #env=$(cat /etc/facter/facts.d/env.txt | cut -d"=" -f2)
       #wget http://10.140.221.229/$env/stable_repo.yaml -O /etc/puppet/hiera/data/repo.yaml
       #if [ -d "/etc/puppet/hiera.overrides"];then
       #  cp /etc/puppet/hiera/data/repo.yaml /etc/puppet/hiera.overrides/data/repo.yaml
       #fi
       (echo 'File<| title == "/etc/consul" |> { purge => false }'; echo 'File<| title == "sources.list.d" |> { purge => false }'; echo 'include rjil::system::apt' ) | puppet apply --logdest=syslog --config_version='python -m jiocloud.orchestrate current_version'

       apt-get update
       apt-get dist-upgrade -o Dpkg::Options::="--force-confold" -y
       run_puppet
elif [ $rv -eq 1 ]
then
       :
elif [ $rv -eq 2 ]
then
       :
elif [ $rv -eq 3 ]
then
       # Maybe we're the first consul node (or some other weirdness is going on).
       # Let's just run Puppet and see if things normalize
       run_puppet
fi
python -m jiocloud.orchestrate local_health
rv=$?
if [ $rv -ne 0 ]
then
  # if we are failing, run puppet to see if it fixes itself
  run_puppet
fi
validate_service
python -m jiocloud.orchestrate local_version $pending_version
python -m jiocloud.orchestrate update_own_info
