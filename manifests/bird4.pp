class ffgt_gln_gw::bird4 (
  $router_id = $ffgt_gln_gw::params::router_id,
  $icvpn_as  = $ffgt_gln_gw::params::icvpn_as,
  $include_chaos = $ffgt_gln_gw::params::include_chaos_routes,
  $include_dn42  = $ffgt_gln_gw::params::include_dn42_routes
) inherits ffgt_gln_gw::params {

  require ffgt_gln_gw::resources::repos
 
  ffgt_gln_gw::monitor::nrpe::check_command {
    "bird":
      command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C bird';
  }

  package { 
    'bird':
      ensure => installed,
      require => [
        File['/etc/apt/preferences.d/bird'],
        Apt::Source['debian-backports']
      ];
  }
 
  file {
    '/etc/bird/bird.conf.d/':
      ensure => directory,
      mode => "0755",
      owner => root,
      group => root,
      require => File['/etc/bird/bird.conf'];
    '/etc/bird/bird.conf':
      ensure => file,
      mode => "0644",
      content => template("ffgt_gln_gw/etc/bird/bird.conf.erb"),
      require => [Package['bird'],File['/etc/bird/']];
    '/etc/bird.conf':
      ensure => link,
      target => '/etc/bird/bird.conf',
      require => File['/etc/bird/bird.conf'],
      notify => Service['bird'];
  } 

  service {
    'bird':
      ensure => running,
      enable => true,
      hasstatus => false,
      restart => "/usr/sbin/birdc configure",
      require => Package['bird'],
      subscribe => File['/etc/bird/bird.conf'];
  }

  include ffgt_gln_gw::resources::bird
}

define ffgt_gln_gw::bird4::mesh (
  $mesh_code,

  $mesh_ipv4_address,
  $range_ipv4,
  $mesh_ipv6_address,
  $mesh_peerings, # YAML data file for local peerings

  $icvpn_as,

  $site_ipv4_prefix,
  $site_ipv4_prefixlen,
  $include_chaos,
  $include_dn42,
) {

  include ffgt_gln_gw::bird4

  file_line { "bird-${mesh_code}-include":
    path => '/etc/bird/bird.conf',
    line => "include \"/etc/bird/bird.conf.d/${mesh_code}.conf\";",
    require => File['/etc/bird/bird.conf'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/${mesh_code}.conf":
    mode => "0644",
    content => template("ffgt_gln_gw/etc/bird/bird.interface.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-${mesh_code}-include"],
      Service['bird']
    ]
  }
}

define ffgt_gln_gw::bird4::icvpn (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],

  $tinc_keyfile,
  ){

  include ffgt_gln_gw::bird4
  include ffgt_gln_gw::resources::meta
  include ffgt_gln_gw::icvpn

  $icvpn_name = $name

  file_line { 
    "icvpn-template":
      path => '/etc/bird/bird.conf',
      line => 'include "/etc/bird/bird.conf.d/icvpn-template.conf";',
      require => File['/etc/bird/bird.conf'],
      notify  => Service['bird'];
  }->
  file_line {
    "icvpn-include":
      path => '/etc/bird/bird.conf',
      line => 'include "/etc/bird/bird.conf.d/icvpn-peers.conf";',
      require => [
        File['/etc/bird/bird.conf'],
        Class['ffgt_gln_gw::resources::meta']
      ],
      notify  => Service['bird'];
  } 

  # Process meta data from tinc directory
  file { "/etc/bird/bird.conf.d/icvpn-template.conf":
    mode => "0644",
    content => template("ffgt_gln_gw/etc/bird/bird.icvpn-template.conf.erb"),
    require => [ 
      File['/etc/bird/bird.conf.d/'],
      Package['bird'],
      Class['ffgt_gln_gw::tinc'],
    ],
    notify  => [
      Service['bird'],
      File_line['icvpn-include'],
      File_line['icvpn-template']
    ];
  } 
}
