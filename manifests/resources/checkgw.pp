class ff_gln_gw::resources::checkgw (
  $gw_control_ip     = "8.8.8.8",     # Control ip addr
  $gw_bandwidth      = 54,            # How much bandwith we should have up/down per mesh interface
) {

  file {
    '/usr/local/bin/check-gateway':
      ensure => file,
      mode => "0755",
      source => 'puppet:///modules/ff_gln_gw/usr/local/bin/check-gateway';
  }

  ff_gln_gw::resources::ff_gln_gw::field {
    "GW_CONTROL_IP": value => "${gw_control_ip}";
  }

  cron {
   'check-gateway':
     command => '/usr/local/bin/check-gateway',
     user    => root,
     minute  => '*';
  }
}
