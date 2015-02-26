# Common scripts for update scripts.
class ffgt_gln_gw::resources::update () {
  file {
    '/usr/local/include/ffgt_gln_gw-update.common':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => 'puppet:///modules/ffgt_gln_gw/usr/local/include/ffgt_gln_gw-update.common';
  }
}
