define ffgt_gln_gw::fastd( $mesh_name
                     , $mesh_code
                     , $mesh_mac
                     , $mesh_mtu = 1426

                     , $fastd_secret
                     , $fastd_port

                     , $fastd_peers_git
                     , $peer_limit
                     , $use_blacklist
                     ) {
  #validate_re($mesh_mac, '^de:ad:be:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}$')

  include ffgt_gln_gw::resources::fastd
  include ffgt_gln_gw::resources::fastd::auto_fetch_keys

  ffgt_gln_gw::monitor::nrpe::check_command {
    "fastd_${mesh_code}":
      command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C fastd -a \"${mesh_code}-mesh-vpn\"";
  }

  file {
    "/etc/fastd/${mesh_code}-mesh-vpn/":
      ensure =>directory,
             require => Package[ffgt_gln_gw::resources::fastd];
    "/etc/fastd/${mesh_code}-mesh-vpn/backbone":
      ensure =>directory,
             require => Package[ffgt_gln_gw::resources::fastd];
    "/etc/fastd/${mesh_code}-mesh-vpn/fastd.conf":
      ensure => file,
             notify => Service[ffgt_gln_gw::resources::fastd],
             content => template('ffgt_gln_gw/etc/fastd/fastd.conf.erb');
    "/etc/fastd/${mesh_code}-mesh-vpn/fastd-blacklist.sh":
      ensure => file,
             notify => Service[ffgt_gln_gw::resources::fastd],
             content => template('ffgt_gln_gw/etc/fastd/fastd-blacklist.sh.erb'),
             mode => '0766';
   "/etc/fastd/${mesh_code}-mesh-vpn/fastd-blacklist.json":
      ensure => file,
             notify => Service[ffgt_gln_gw::resources::fastd],
             content => template('ffgt_gln_gw/etc/fastd/fastd-blacklist.json.erb');
    "/etc/fastd/${mesh_code}-mesh-vpn/secret.conf":
      ensure => file,
      source => $fastd_secret,
      mode => '0600',
  } ->
  ffgt_gln_gw::batman-adv { "ffgt_gln_gw_batman_adv_${mesh_code}":
    mesh_code => $mesh_code;
  } ->
  vcsrepo { "/etc/fastd/${mesh_code}-mesh-vpn/peers":
    ensure   => present,
    provider => git,
    source   => $fastd_peers_git,
    notify   => Class[ffgt_gln_gw::resources::fastd::auto_fetch_keys];
  } ->
  ffgt_gln_gw::firewall::service { "fastd-${mesh_code}":
    ports  => [$fastd_port],
    protos => ['udp'],
    chains => ['wan']
  }

  file {
    "/etc/fastd/${mesh_code}-mesh-vpn/peers/.git/hooks/post-merge":
       ensure => file,
       owner => 'root',
       group => 'root',
       mode => '0755',
       content => "#!/bin/sh\n/usr/local/bin/update-fastd-keys reload",
       require => Vcsrepo["/etc/fastd/${mesh_code}-mesh-vpn/peers"];
  }

  file_line {
   "root_bashrc_fastd_query_${mesh_code}":
     path => '/root/.bashrc',
     line => "alias fastd-query-${mesh_code}='FASTD_SOCKET=/var/run/fastd-status.${mesh_code}.sock fastd-query'"
  }

  ffgt_gln_gw::etckeeper::ignore { "/etc/fastd/${mesh_code}-mesh-vpn/peers/": }

}
