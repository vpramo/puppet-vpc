class rjil::omd_client (
  $check_mk_version = '1.2.6p12-1',
  $download_source  = 'http://10.140.221.229/share/agents/',
) {
  class { '::omd::client':
    check_mk_version => $check_mk_version,
    download_source  => $download_source,
  }
}
