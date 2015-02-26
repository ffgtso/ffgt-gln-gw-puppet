class ffgt_gln_gw::maintenance (
  $maintenance = $ffgt_gln_gw::params::maintenance
) inherits ffgt_gln_gw::params {
  include ffgt_gln_gw::resources::ffgt_gln_gw

  Class['ffgt_gln_gw::resources::ffgt_gln_gw'] ->

  ffgt_gln_gw::resources::ffgt_gln_gw::field {
    "MAINTENANCE": value => "${maintenance}";
  }

  file {
    '/usr/local/bin/maintenance':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      source => 'puppet:///modules/ffgt_gln_gw/usr/local/bin/maintenance';
  }
}
