class ff_gln_gw::bird6 (
  $router_id = $ff_gln_gw::params::router_id,
  $icvpn_as  = $ff_gln_gw::params::icvpn_as
) inherits ff_gln_gw::params {
  require ff_gln_gw::resources::repos
 
  ff_gln_gw::monitor::nrpe::check_command {
    "bird6":
      command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C bird6';
  }

  package { 
    'bird6':
      ensure => installed,
      require => [
        File['/etc/apt/preferences.d/bird'],
        Apt::Source['debian-backports']
      ];
  }
 
  file {
    '/etc/bird/bird6.conf.d/':
      ensure => directory,
      mode => "0755",
      owner => root,
      group => root,
      require => File['/etc/bird/bird6.conf'];
    '/etc/bird/bird6.conf':
      ensure => file,
      mode => "0644",
      content => template("ff_gln_gw/etc/bird/bird6.conf.erb"),
      require => [Package['bird6'],File['/etc/bird/']];
    '/etc/bird6.conf':
      ensure => link,
      target => '/etc/bird/bird6.conf',
      require => File['/etc/bird/bird6.conf'],
      notify => Service['bird6'];
  }

  file {
    '/etc/bird/bird6.conf.inc':
      ensure => file,
      mode => "0644",
      content => template("ff_gln_gw/etc/bird/bird6.conf.inc.erb"),
      require => [Package['bird6'],File['/etc/bird/']];
  }

  file_line { "bird6-include":
    path => '/etc/bird/bird6.conf',
    line => "include \"/etc/bird/bird6.conf.inc\";",
    require => File['/etc/bird/bird6.conf'],
    notify  => Service['bird6'];
  }

  exec { "sort-bird6-include":
    command => "/usr/bin/sort -o /etc/bird/bird6.conf.inc /etc/bird/bird6.conf.inc",
    cwd => "/tmp",
    subscribe => File['/etc/bird/bird6.conf.inc'],
  }

  service {
    'bird6':
      ensure => running,
      enable => true,
      hasstatus => false,
      restart => "/usr/bin/sort -o /etc/bird/bird6.conf.inc /etc/bird/bird6.conf.inc ; /usr/sbin/birdc6 configure",
      require => Package['bird6'],
      subscribe => File['/etc/bird/bird6.conf.inc'];
  }

  include ff_gln_gw::resources::bird
}


define ff_gln_gw::bird6::mesh (
  $mesh_code,
  $mesh_ipv4_address,
  $mesh_ipv6_address,
  $mesh_peerings, # YAML data file for local peerings
  $have_mesh_peerings = "no", # Actually require & use $mesh_peerings
  $icvpn_as,
  $site_ipv6_prefix,
  $site_ipv6_prefixlen,
) {
  include ff_gln_gw::bird6

  $range_ipv6 = "${site_ipv6_prefix}/${site_ipv6_prefixlen}"  # This should not happen; FIXME!

  file_line { "bird6-${mesh_code}-include":
    path => '/etc/bird/bird6.conf.inc',
    line => "include \"/etc/bird/bird6.conf.d/01-${mesh_code}.conf\";",
    require => File['/etc/bird/bird6.conf.inc'],
    notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/01-${mesh_code}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.interface.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird6']],
    notify  => [
      File_line["bird6-${mesh_code}-include"],
      Service['bird6']
    ]
  }
}


define ff_gln_gw::bird6::srv (
  $mesh_code,
  $srv_ipv4_address,
  $srv_ipv6_address,
  $icvpn_as,
) {
  include ff_gln_gw::bird6

  file_line { "bird6-${mesh_code}-srv-include":
    path => '/etc/bird/bird6.conf.inc',
    line => "include \"/etc/bird/bird6.conf.d/05-srv-${mesh_code}.conf\";",
    require => File['/etc/bird/bird6.conf.inc'],
    notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/05-srv-${mesh_code}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.srv-interface.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird6']],
    notify  => [
      File_line["bird6-${mesh_code}-srv-include"],
      Service['bird6']
    ]
  }
}


define ff_gln_gw::bird6::ospf (
  $mesh_code,
  $range_ipv6,
  $router_id = $ff_gln_gw::params::router_id,
  $ospf_peerings, # YAML data file for local backbone peerings
  $ospf_links,    # YAML data file for local interconnects
  $have_ospf_peerings = "no", # Actually require & use $ospf_peerings
  $have_ospf_links = "no",    # Actually require & use $ospf_links
  $ospf_type = "root"         # root/leaf: root reexports routes, leaf only exports statics.
) {
  include ff_gln_gw::bird6

  file_line { "bird6-ospf-${mesh_code}-include":
    path => '/etc/bird/bird6.conf.inc',
    line => "include \"/etc/bird/bird6.conf.d/05-ospf6-${mesh_code}.conf\";",
    require => File['/etc/bird/bird6.conf.inc'],
    notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/05-ospf6-${mesh_code}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/ospf-mesh6.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird6']],
    notify  => [
      File_line["bird6-ospf-${mesh_code}-include"],
      Service['bird']
    ]
  }
}


# Allow local additions via local.conf
define ff_gln_gw::bird6::local (
) {
  include ff_gln_gw::bird6

  file_line { "bird6-local-include":
    path => '/etc/bird/bird6.conf.inc',
    line => "include \"/etc/bird/bird6.conf.d/99-local.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => [ Exec['touch-local6-conf'], Service['bird'] ];
  }

  exec { "touch-local6-conf":
    command => "/usr/bin/touch -a 99-local.conf",
    cwd => "/etc/bird/bird6.conf.d/",
    require => File['/etc/bird/bird6.conf.inc'],
  }

  file { "/etc/bird/bird6.conf.d/99-local.conf":
    mode => "0644",
    notify  => [
      File_line["bird6-local-include"],
      Service['bird6']
    ]
  }
}

define ff_gln_gw::bird6::local_route (
  $local_rt,
  $local_if
) {
  include ff_gln_gw::bird6

  file_line {
    "bird6-localrt-${name}":
      path => '/etc/bird/bird6.conf.d/99-local.conf',
      line => "protocol static 'localrt-${name}' { table ospf_ffgt; route ${local_rt} via \"${local_if}\"; };",
      require => File['/etc/bird/bird6.conf.d/99-local.conf'],
      notify  => Service['bird6'];
  }
}

define ff_gln_gw::bird6::icvpn (
  $icvpn_as = $ff_gln_gw::params::icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],
  $mesh_code,
  $tinc_keyfile,
  ){
  include ff_gln_gw::bird6
  include ff_gln_gw::resources::meta
  $icvpn_name = $name
  include ff_gln_gw::icvpn

  file_line {
    "icvpn-template6":
      path => '/etc/bird/bird6.conf.inc',
      line => 'include "/etc/bird/bird6.conf.d/03-icvpn.conf";',
      require => File['/etc/bird/bird6.conf.inc'],
      notify  => Service['bird6'];
  }->
  file_line {
    "icvpn-include6":
      path => '/etc/bird/bird6.conf.inc',
      line => 'include "/etc/bird/bird6.conf.d/icvpn-peers.conf";',
      require => [
        File['/etc/bird/bird6.conf.inc'],
        Class['ff_gln_gw::resources::meta']
      ],
      notify  => Service['bird6'];
  }

  # Process meta data from tinc directory
  file { "/etc/bird/bird6.conf.d/03-icvpn.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.icvpn-template.conf.erb"),
    require => [
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6'],
      Class['ff_gln_gw::tinc'],
    ],
    notify  => [
      Service['bird6'],
      File_line['icvpn-include6'],
      File_line['icvpn-template6']
    ];
  }
}


define ff_gln_gw::bird6::ibgp::setup (
  $our_as = $ff_gln_gw::params::icvpn_as
) {
  include ff_gln_gw::bird6
  include ff_gln_gw::resources::meta

  file_line {
    "bird6-ibgp-base":
      path => '/etc/bird/bird6.conf.inc',
      line => "include \"/etc/bird/bird6.conf.d/02-ibgp-A-aaabase.conf\";",
      require => File['/etc/bird/bird6.conf.inc'],
      notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/02-ibgp-A-aaabase.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.ibgp-base.conf.erb"),
    require => [
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6']
    ],
    notify  => [
      Service['bird6'],
      File_line["bird6-ibgp-base"]
    ];
  }
}

define ff_gln_gw::bird6::ibgp (
  $peers,
  $gre_yaml,
  $our_as = $ff_gln_gw::params::icvpn_as,
  $next_hop_self = ""
) {
  include ff_gln_gw::bird6
  include ff_gln_gw::resources::meta

  file_line {
    "bird6-ibgp-${name}":
      path => '/etc/bird/bird6.conf.inc',
      line => "include \"/etc/bird/bird6.conf.d/02-ibgp-B-${name}.conf\";",
      require => File['/etc/bird/bird6.conf.inc'],
      notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/02-ibgp-B-${name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.ibgp-template.conf.erb"),
    require => [
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6']
    ],
    notify  => [
      Service['bird6'],
      File_line["bird6-ibgp-${name}"]
    ];
  }
}


define ff_gln_gw::bird6::ebgp::setup (
  $mesh_code,
  $our_as = $ff_gln_gw::params::icvpn_as,
) {
  include ff_gln_gw::bird6
  include ff_gln_gw::resources::meta

  $ipv6_main_prefix = $ff_gln_gw::params::ipv6_main_prefix

  file_line {
    "bird6-ebgp-base":
      path => '/etc/bird/bird6.conf.inc',
      line => "include \"/etc/bird/bird6.conf.d/03-ebgp-A-aaabase.conf\";",
      require => File['/etc/bird/bird6.conf.inc'],
      notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/03-ebgp-A-aaabase.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.ebgp-base.conf.erb"),
    require => [
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6']
    ],
    notify  => [
      Service['bird6'],
      File_line["bird6-ebgp-base"]
    ];
  }
}

define ff_gln_gw::bird6::ebgp (
  $peers,
  $mesh_code,
  $type = "peer",
  $gre_yaml,
  $multihop = "",
  $password = "",
  $bgp_options = "",
  $our_as = $ff_gln_gw::params::icvpn_as,
) {
  include ff_gln_gw::bird6
  include ff_gln_gw::resources::meta

  $ipv6_main_prefix = $ff_gln_gw::params::ipv6_main_prefix

  if $type == "special" {
    file_line {
      "bird6-ebgp-special-${name}":
        path => '/etc/bird/bird6.conf.inc',
        line => "include \"/etc/bird/bird6.conf.d/03-ebgp-B-${name}-init.conf\";",
        require => File['/etc/bird/bird6.conf.inc'],
        notify  => Service['bird6'];
    }

    file { "/etc/bird/bird6.conf.d/03-ebgp-B-${name}-init.conf":
      mode => "0644",
      content => template("ff_gln_gw/etc/bird/bird6.ebgp-special.conf.erb"),
      replace => false,
      require => [
        File['/etc/bird/bird6.conf.d/'],
        Package['bird6']
      ],
      notify  => [
        Service['bird6'],
        File_line["bird6-ebgp-special-${name}"]
      ];
    }
  }

  file_line {
    "bird6-ebgp-${name}":
      path => '/etc/bird/bird6.conf.inc',
      line => "include \"/etc/bird/bird6.conf.d/03-ebgp-X-${name}-main.conf\";",
      require => File['/etc/bird/bird6.conf.inc'],
      notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/03-ebgp-X-${name}-main.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.ebgp-template.conf.erb"),
    require => [
      File['/etc/bird/bird6.conf.d/'],
      Package['bird6']
    ],
    notify  => [
      Service['bird6'],
      File_line["bird6-ebgp-${name}"]
    ];
  }
}
