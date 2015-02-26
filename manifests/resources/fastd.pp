class ffgt_gln_gw::resources::fastd {

  include ffgt_gln_gw::resources::repos

  Class[ffgt_gln_gw::resources::repos]
  -> package { 'ffgt_gln_gw::resources::fastd': name => "fastd", ensure => installed;}
  -> service { 'ffgt_gln_gw::resources::fastd': name => "fastd", hasrestart => true, ensure => running, enable => true; }

  file {
    '/usr/local/bin/fastd-query':
      ensure => file,
      mode => '0755',
      require => [
        Package['jq'],
        Package['socat'],
      ],
      source => 'puppet:///modules/ffgt_gln_gw/usr/local/bin/fastd-query';
  }

  package { ['jq','socat']:
    ensure => installed,
    require => Class[ffgt_gln_gw::resources::repos];
  }
}

class ffgt_gln_gw::resources::fastd::auto_fetch_keys {

  include ffgt_gln_gw::resources::update

  file { '/usr/local/bin/update-fastd-keys':
    ensure => file,
    mode => '0755',
    source => 'puppet:///modules/ffgt_gln_gw/usr/local/bin/update-fastd-keys',
    require => Class['ffgt_gln_gw::resources::update'];
  }

  file { '/usr/local/bin/autoupdate_fastd_keys': ensure => absent; }

  package { 'ffgt_gln_gw::resources::cron': name => "cron", ensure => installed; }
  -> cron {
   'autoupdate_fastd':
     command => '/usr/local/bin/update-fastd-keys pull',
     user    => root,
     minute  => '*/5';
  }
}
