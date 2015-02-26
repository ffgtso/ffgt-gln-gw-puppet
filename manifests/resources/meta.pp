class ffgt_gln_gw::resources::meta {

  include ffgt_gln_gw::resources::update

  vcsrepo { 
     '/var/lib/icvpn-meta/':
       ensure => present,
       provider => git,
       source => "https://github.com/freifunk/icvpn-meta.git";
     '/opt/icvpn-scripts/':
       ensure => present,
       provider => git,
       source => "https://github.com/freifunk/icvpn-scripts.git",
       require => [
         Vcsrepo['/var/lib/icvpn-meta/'],
         Package['python-yaml']
       ];
  }

  file {
    "/var/lib/icvpn-meta/.git/hooks/post-merge":
       ensure => file,
       owner => 'root',
       group => 'root',
       mode => '0755',
       content => "#!/bin/sh\n/usr/local/bin/update-meta reload",
       require => Vcsrepo['/var/lib/icvpn-meta/'];
  }

  package {
    'python-yaml':
      ensure => installed;
  }


  file { 
    '/usr/local/bin/update-meta':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0754',
      source => "puppet:///modules/ffgt_gln_gw/usr/local/bin/update-meta",
      require => Class['ffgt_gln_gw::resources::update'];
  }

  exec {
    'update-meta':
      command => '/usr/local/bin/update-meta reload',
      require => [
        Vcsrepo['/var/lib/icvpn-meta/'],
        File['/usr/local/bin/update-meta'],
      ];
  }

  cron {
    'update-icvpn-meta':
      command => '/usr/local/bin/update-meta pull',
      user => root,
      minute => '0',
      require => [
        File['/usr/local/bin/update-meta']
      ];
  }
}

define ffgt_gln_gw::resources::meta::dns_zone_exclude(){
  ffgt_gln_gw::resources::ffgt_gln_gw::field {
    "DNS_ZONE_EXCLUDE_${name}": value => "${name}";
  }
}
