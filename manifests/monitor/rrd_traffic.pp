define ff_gln_gw::monitor::rrd_traffic (
  $rrd_interfaces, # YAML file with interface, description
  $rrd_upload_url  # URL to upload data to (e. g. http://guetersloh.freifunk.net/rrd_traffic_upload.php)
) {
  package {
    'perl-base':
      ensure => installed;
  }

  file { 
    '/root/rrd_traffic_slave.pl':
      ensure => file, 
      mode => '0755',
      owner => 'root',
      group => 'root',
      require => Package['perl-base'],
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

  cron {
   'rrd_traffic_slave':
     command => '/root/rrd_traffic_slave.pl --slave >/dev/null 2>&1',
     user    => root,
     minute  => '*/5',
     hour    => '*',
     require => File['/root/rrd_traffic_slave.pl'];
  }

  cron {
   'rrd_traffic_upload':
     command => 'sleep 20 ; /root/rrd_traffic_upload.sh >/dev/null 2>&1',
     user    => root,
     minute  => '*/5',
     hour    => '*',
     require => File['/root/rrd_traffic_upload.sh'];
  }
}
