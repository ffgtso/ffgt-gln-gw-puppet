define ff_gln_gw::monitor::rrd_traffic (
  $rrd_interfaces, # YAML file with interface, description
  $rrd_upload_url  # URL to upload data to (e. g. http://guetersloh.freifunk.net/rrd_traffic_upload.php)
) {

  file { 
    '/root/rrd_traffic_slave.pl':
      ensure => file, 
      mode => '0755',
      owner => 'root',
      group => 'root',
      require => Package['perl'],
      content => template('ff_gln_gw/root/rrd_traffic_slave.pl.erb');
  }

  file {
    '/root/rrd_traffic_upload.sh':
      ensure => file,
      mode => '0755',
      owner => 'root',
      group => 'root',
      content => template('ff_gln_gw/root/rrd_traffic_upload.sh.erb');
  }
}
