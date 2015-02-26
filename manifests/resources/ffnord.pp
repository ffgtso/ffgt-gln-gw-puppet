# Ensure existence of global configuration file
# for various scripts from this module.
class ffgt_gln_gw::resources::ffgt_gln_gw {
  file { '/etc/ffgt_gln_gw':
    ensure => file,
    mode => "0644";
  }
}

# Define new configuration keys and set a 
# default value. Because stdlib::file_line 
# can only match and then replace, but not
# search and if not exists insert, calling
# this value will always write the default
# value.
define ffgt_gln_gw::resources::ffgt_gln_gw::field(
  $value = ''
) { 
  include ffgt_gln_gw::resources::ffgt_gln_gw

  file_line { "${name}":
      path => '/etc/ffgt_gln_gw',
      match => "^${name}=.*",
      line => "${name}=${value}";
  }
}
