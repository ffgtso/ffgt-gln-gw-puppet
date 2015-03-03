class ff_gln_gw::maintenance (
  $maintenance = $ff_gln_gw::params::maintenance
) inherits ff_gln_gw::params {
  include ff_gln_gw::resources::ff_gln_gw

  Class['ff_gln_gw::resources::ff_gln_gw'] ->

  ff_gln_gw::resources::ff_gln_gw::field {
    "MAINTENANCE": value => "${maintenance}";
  }

  file {
    '/usr/local/bin/maintenance':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      source => 'puppet:///modules/ff_gln_gw/usr/local/bin/maintenance';
  }
}
