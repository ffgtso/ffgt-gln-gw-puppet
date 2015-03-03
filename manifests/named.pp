class ff_gln_gw::named () {

  include ff_gln_gw::resources::meta

  ff_gln_gw::monitor::nrpe::check_command {
    "named":
      command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C named';
  }

  package {
    'bind9':
      ensure => installed;
  }

  service {
    'bind9':
      ensure => running,
      enable => true,
      hasrestart => true,
      restart => '/usr/sbin/rndc reload',
      require => [
        Package['bind9'],
        File['/etc/bind/named.conf.options'],
        File_line['icvpn-meta'],
        Class['ff_gln_gw::resources::meta']
      ]
  }

  file {
    '/etc/bind/named.conf.options':
      ensure  => file,
      source  => "puppet:///modules/ff_gln_gw/etc/bind/named.conf.options",
      require => [Package['bind9']],
      notify  => [Service['bind9']];
  }

  file_line {
    'icvpn-meta':
       path => '/etc/bind/named.conf',
       line => 'include "/etc/bind/named.conf.icvpn-meta";',
       before => Class['ff_gln_gw::resources::meta'],
       require => [
         Package['bind9']
       ];
  }

  ff_gln_gw::firewall::service { 'named':
    chains => ['mesh'],
    ports  => ['53'],
    protos => ['udp','tcp'];
  }
}

## ff_gln_gw::named::zone
# Define a custom zone and receive the zone file from a git repository.
#
# The here defined resource is assuming that the configuration file
# is named '${zone_name}.conf'.
define ff_gln_gw::named::zone (
  $zone_git, # git repo with zone files
  $exclude_meta = '' # optinal exclude zone from icvpn-meta
) {
  include ff_gln_gw::named

  $zone_name = $name

  file{
    "/etc/bind/zones/":
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755',
      require => Package['bind9'];
  }

  vcsrepo { "/etc/bind/zones/${zone_name}/":
    ensure   => present,
    provider => git,
    source   => $zone_git,
    require  => [
      File["/etc/bind/zones/"],
    ];
  }

  file{
    "/etc/bind/zones/${zone_name}/.git/hooks/post-merge":
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      content => "#!/bin/sh\n/usr/local/bin/update-zones reload",
      require => Vcsrepo["/etc/bind/zones/${zone_name}/"];
  }

  file_line {
    "zone-${zone_name}":
      path => '/etc/bind/named.conf',
      line => "include \"/etc/bind/zones/${zone_name}/${zone_name}.conf\";",
      require => [
        Vcsrepo["/etc/bind/zones/${zone_name}/"]
      ];
  }

  file {
    '/usr/local/bin/update-zones':
     ensure => file,
     owner => 'root',
     group => 'root',
     mode => '0755',
     source => 'puppet:///modules/ff_gln_gw/usr/local/bin/update-zones',
     require =>  Vcsrepo["/etc/bind/zones/${zone_name}/"];
  }

  cron {
    'update-zones':
      command => '/usr/local/bin/update-zones pull',
      user => root,
      minute => [0,30],
      require => File['/usr/local/bin/update-zones'];
  }

  if $exclude_meta != '' {
    ff_gln_gw::resources::meta::dns_zone_exclude { 
      "${exclude_meta}": 
        before => Exec['update-meta'];
    }
  }
}

define ff_gln_gw::named::listen (
  $ipv4_address,
  $ipv6_address,
) {

  include ff_gln_gw::named

  ff_gln_gw::named::listen_v4 { "${name}":
    ipv4_address => $ipv4_address,
  }

  ff_gln_gw::named::listen_v6 { "${name}":
    ipv6_address => $ipv6_address,
  }
}

define ff_gln_gw::named::listen_v4 (
  $ipv4_address,
) {

  include ff_gln_gw::named

  exec { "${name}_listen-on":
    command => "/bin/sed -i -r 's/(listen-on .*)\\}/\\1 ${ipv4_address};}/' /etc/bind/named.conf.options",
    require => File['/etc/bind/named.conf.options'];
  }
}

define ff_gln_gw::named::listen_v6 (
  $ipv6_address,
) {

  include ff_gln_gw::named

  exec { "${name}_listen-on-v6":
    command => "/bin/sed -i -r 's/(listen-on-v6 .*)\\}/\\1 ${ipv6_address};}/' /etc/bind/named.conf.options",
    require => File['/etc/bind/named.conf.options'];
  }
}

define ff_gln_gw::named::allow (
  $ip_prefix,
  $ip_prefixlen,
) {

  include ff_gln_gw::named

  exec { "${name}_allow":
    command => "/bin/sed -i -r 's/(allow-query .*)\\}/\\1 ${ip_prefix}\\/${ip_prefixlen};}/' /etc/bind/named.conf.options",
    require => File['/etc/bind/named.conf.options'];
  }
}
