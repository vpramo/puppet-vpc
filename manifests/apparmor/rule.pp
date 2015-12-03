##
# Define: rjil::apparmor::rule
#  Manage apparmor rules
#  Setting up single rule assume that the file is already exists, if you want to
# manage complete rule file, use $content or $source instead.
#
define rjil::apparmor::rule (
  $file_path = undef,
  $content   = undef,
  $source    = undef,
  $rule      = $name,
  $ensure    = 'present',
) {

  include rjil::apparmor

  ##
  # if content or source set, it assumed that you need to write the entire file
  ##
  if ($content) or ($source) {
    if ($content) and  ($source) {
      fail('Should not set both content and source')
    }

    if ! $file_path {
      $file_path_orig = $name
    } else {
      $file_path_orig = $file_path
    }

    file { $file_path_orig:
      ensure  => $ensure,
      content => $content,
      source  => $source,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      notify  => Service['apparmor'],
    }

  ##
  #  If rule is set, it is to update an existing rule file to be updated with the rule provided.
  ##
  }  elsif $rule {

    if ! $file_path {
      fail('file_path should be set to an existing apparmor rule file')
    }

    file_line { "apparmor_rule_${rule}":
      ensure => $ensure,
      line   => $rule,
      path   => $file_path,
      notify => Service['apparmor'],
    }

  } else {
    fail('either rule or rule file contents/source must be provided')
  }
}
