class ff_gln_gw::resources::fastd {

  include ff_gln_gw::resources::repos

  Class[ff_gln_gw::resources::repos]
  -> package { 'ff_gln_gw::resources::fastd': name => "fastd", ensure => installed;}
  -> service { 'ff_gln_gw::resources::fastd': name => "fastd", hasrestart => true, ensure => running, enable => true; }

  file {
    '/usr/local/bin/fastd-query':
      ensure => file,
      mode => '0755',
      require => [
        Package['jq'],
        Package['socat'],
      ],
      source => 'puppet:///modules/ff_gln_gw/usr/local/bin/fastd-query';
  }

  file {
    '/usr/local/bin/calculate_fastd_threshold.sh':
      ensure => file,
      mode => '0766',
      content => template('ff_gln_gw/etc/fastd/calculate_fastd_threshold.sh.erb');
  }

  cron {
    'check_fastd_connections':
      command => '/usr/local/bin/calculate_fastd_threshold.sh',
      user => root,
      minute => [*],
      require => File['/usr/local/bin/calculate_fastd_threshold.sh'];
  }

  package { ['jq','socat']:
    ensure => installed,
    require => Class[ff_gln_gw::resources::repos];
  }
}

class ff_gln_gw::resources::fastd::auto_fetch_keys {

  include ff_gln_gw::resources::update

  file { '/usr/local/bin/update-fastd-keys':
    ensure => file,
    mode => '0755',
    source => 'puppet:///modules/ff_gln_gw/usr/local/bin/update-fastd-keys',
    require => Class['ff_gln_gw::resources::update'];
  }

  file { '/usr/local/bin/autoupdate_fastd_keys': ensure => absent; }

  package { 'ff_gln_gw::resources::cron': name => "cron", ensure => installed; }
  -> cron {
   'autoupdate_fastd':
     command => '/usr/local/bin/update-fastd-keys pull',
     user    => root,
     minute  => '*/5';
  }
}
