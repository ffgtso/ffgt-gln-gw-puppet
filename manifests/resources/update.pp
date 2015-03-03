# Common scripts for update scripts.
class ff_gln_gw::resources::update () {
  file {
    '/usr/local/include/ff_gln_gw-update.common':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => 'puppet:///modules/ff_gln_gw/usr/local/include/ff_gln_gw-update.common';
  }
}
