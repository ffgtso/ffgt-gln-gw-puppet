class ff_gln_gw::bird4 (
  $router_id = $ff_gln_gw::params::router_id,
  $icvpn_as  = $ff_gln_gw::params::icvpn_as,
  $include_chaos = $ff_gln_gw::params::include_chaos_routes,
  $include_dn42  = $ff_gln_gw::params::include_dn42_routes,
  $provides_uplink = $ff_gln_gw::params::provides_uplink
) inherits ff_gln_gw::params {

  require ff_gln_gw::resources::repos
 
  ff_gln_gw::monitor::nrpe::check_command {
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

  if $provides_uplink == "yes" {
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
        content => template("ff_gln_gw/etc/bird/bird-provide.conf.erb"),
        require => [Package['bird'],File['/etc/bird/']];
      '/etc/bird.conf':
        ensure => link,
        target => '/etc/bird/bird.conf',
        require => File['/etc/bird/bird.conf'],
        notify => Service['bird'];
    }
  } else {
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
        content => template("ff_gln_gw/etc/bird/bird.conf.erb"),
        require => [Package['bird'],File['/etc/bird/']];
      '/etc/bird.conf':
        ensure => link,
        target => '/etc/bird/bird.conf',
        require => File['/etc/bird/bird.conf'],
        notify => Service['bird'];
    }
  }

  file {
    '/etc/bird/bird.conf.inc':
      ensure => file,
      mode => "0644",
      content => template("ff_gln_gw/etc/bird/bird.conf.inc.erb"),
      require => [Package['bird'],File['/etc/bird/']];
  }

  file_line { "bird4-include":
    path => '/etc/bird/bird.conf',
    line => "include \"/etc/bird/bird.conf.inc\";",
    require => File['/etc/bird/bird.conf'],
    notify  => Service['bird'];
  }

  exec { "sort-bird4-include":
    command => "/usr/bin/sort -o /etc/bird/bird.conf.inc /etc/bird/bird.conf.inc",
    cwd => "/tmp",
    subscribe => File['/etc/bird/bird.conf.inc'],
  }

  service {
    'bird':
      ensure => running,
      enable => true,
      hasstatus => false,
      restart => "/usr/bin/sort -o /etc/bird/bird.conf.inc /etc/bird/bird.conf.inc ; /usr/sbin/birdc configure",
      require => Package['bird'],
      subscribe => File['/etc/bird/bird.conf.inc'];
  }

  include ff_gln_gw::resources::bird
}

define ff_gln_gw::bird4::mesh (
  $mesh_code,

  $mesh_ipv4_address,
  $range_ipv4,
  $mesh_ipv6_address,
  $mesh_peerings, # YAML data file for local peerings
  $have_mesh_peerings = "no", # Actually require & use $mesh_peerings
  $icvpn_as,

  $site_ipv4_prefix,
  $site_ipv4_prefixlen,
  $include_chaos = $ff_gln_gw::params::include_chaos_routes,
  $include_dn42  = $ff_gln_gw::params::include_dn42_routes
) {

  include ff_gln_gw::bird4

  file_line { "bird-${mesh_code}-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/01-${mesh_code}.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/01-${mesh_code}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.interface.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-${mesh_code}-include"],
      Service['bird']
    ]
  }
}

define ff_gln_gw::bird4::srv (
  $mesh_code,
  $srv_ipv4_address,
  $srv_ipv6_address,
  $icvpn_as,
) {
  include ff_gln_gw::bird4

  file_line { "bird-${mesh_code}-srv-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/05-srv-${mesh_code}.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/05-srv-${mesh_code}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.srv-interface.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-${mesh_code}-srv-include"],
      Service['bird']
    ]
  }
}

define ff_gln_gw::bird4::ospf (
  $mesh_code,
  $range_ipv4,
  $router_id = $ff_gln_gw::params::router_id,
  $ospf_peerings, # YAML data file for local backbone peerings
  $ospf_links,    # YAML data file for local interconnects
  $have_ospf_peerings = "no", # Actually require & use $ospf_peerings
  $have_ospf_links = "no",    # Actually require & use $ospf_links
  $ospf_type = "root",        # root/leaf: root reexports routes, leaf only exports statics.
  $announce_rid = "yes"       # Shall we announce the RID (set to no if part of mesh)?
) {

  include ff_gln_gw::bird4
  include ff_gln_gw::resources::network

  if $announce_rid == "yes" {
    # Make sure we have our Router ID configured on this host.
    file {
      "/etc/network/interfaces.d/br-rid":
        ensure => file,
        content => template("ff_gln_gw/etc/network/rid-dummy.erb"),
        require => Package['bridge-utils'];
    } ->
    exec {
      "start_dummy_interface_RID":
        command => "/sbin/ifup br-rid",
        unless  => "/bin/ip link show dev br-rid | grep 'DOWN|br-rid' 2> /dev/null";
    }
  }

  file_line { "bird-ospf-${mesh_code}-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/05-ospf-${mesh_code}.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/05-ospf-${mesh_code}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/ospf-mesh.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-ospf-${mesh_code}-include"],
      Service['bird']
    ]
  }
}

# Allow local additions via local.conf
define ff_gln_gw::bird4::local (
) {
  include ff_gln_gw::bird4

  file_line { "bird-local-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/99-local.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => [ Exec['touch-local-conf'], Service['bird'] ];
  }

  exec { "touch-local-conf":
    command => "/usr/bin/touch -a 99-local.conf",
    cwd => "/etc/bird/bird.conf.d/",
    require => File['/etc/bird/bird.conf.inc'],
  }

  file { "/etc/bird/bird.conf.d/99-local.conf":
    mode => "0644",
    notify  => [
      File_line["bird-local-include"],
      Service['bird']
    ]
  }
}

define ff_gln_gw::bird4::icvpn (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],
  $include_chaos = $ff_gln_gw::params::include_chaos_routes,
  $include_dn42  = $ff_gln_gw::params::include_dn42_routes,
  $mesh_code,
  $tinc_keyfile,
  ){

  include ff_gln_gw::bird4
  include ff_gln_gw::resources::meta
  include ff_gln_gw::icvpn

  $icvpn_name = $name

  file_line { 
    "icvpn-template":
      path => '/etc/bird/bird.conf.inc',
      line => 'include "/etc/bird/bird.conf.d/03-icvpn.conf";',
      require => File['/etc/bird/bird.conf.inc'],
      notify  => Service['bird'];
  }->
  file_line {
    "icvpn-include":
      path => '/etc/bird/bird.conf.inc',
      line => 'include "/etc/bird/bird.conf.d/icvpn-peers.conf";',
      require => [
        File['/etc/bird/bird.conf.inc'],
        Class['ff_gln_gw::resources::meta']
      ],
      notify  => Service['bird'];
  } 

  # Process meta data from tinc directory
  file { "/etc/bird/bird.conf.d/03-icvpn.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.icvpn-template.conf.erb"),
    require => [ 
      File['/etc/bird/bird.conf.d/'],
      Package['bird'],
      Class['ff_gln_gw::tinc'],
    ],
    notify  => [
      Service['bird'],
      File_line['icvpn-include'],
      File_line['icvpn-template']
    ];
  } 
}

define ff_gln_gw::bird4::dn42 (
  $icvpn_as,
  $dn42_peerings,
){
  include ff_gln_gw::bird4
  include ff_gln_gw::resources::meta
  include ff_gln_gw::icvpn

  $icvpn_name = $name

  file_line {
    "dn42-template":
      path => '/etc/bird/bird.conf.inc',
      line => 'include "/etc/bird/bird.conf.d/dn42-template.conf";',
      require => File['/etc/bird/bird.conf.inc'],
      notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/dn42-template.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.dn42-template.conf.erb"),
    require => [
      File['/etc/bird/bird.conf.d/'],
      Package['bird'],
    ],
    notify  => [
      Service['bird'],
      File_line['dn42-include'],
    ];
  }
}


define ff_gln_gw::bird4::anycast (
  $mesh_code,
  $anycast_ipv4,
  $anycast_if,
){
  include ff_gln_gw::bird4

  $anycast_srv = $name

  file_line {
    "anycast-${name}-template":
      path => '/etc/bird/bird.conf.inc',
      line => "include \"/etc/bird/bird.conf.d/07-anycast-${name}.conf\";",
      require => File['/etc/bird/bird.conf.inc'],
      notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/07-anycast-${name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/ospf-anycast-template.conf.erb"),
    require => [
      File['/etc/bird/bird.conf.d/'],
      Package['bird'],
    ],
    notify  => [
      Service['bird'],
      File_line["anycast-${name}-template"]
    ];
  }
}
