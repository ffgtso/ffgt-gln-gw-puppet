class ff_gln_gw::vpn ( 
  $gw_vpn_interface  = "tun-anonvpn", # Interface name for the anonymous vpn
  $gw_control_ip     = "8.8.8.8",     # Control ip addr 
  $gw_bandwidth      = 54,            # How much bandwith we should have up/down per mesh interface
) {

  include ff_gln_gw::resources::ff_gln_gw

  class {
    'ff_gln_gw::resources::checkgw':
      gw_control_ip => $gw_control_ip,
      gw_bandwidth => $gw_bandwidth,
  }
}

class ff_gln_gw::vpn::provider () {

  include ff_gln_gw::firewall

  service {'openvpn':
    ensure  => running,
    hasrestart => true,
    require => Package['openvpn'],
    notify => Class['ff_gln_gw::vpn'];
  }
 
  package { 'openvpn':
    ensure => installed;
  }

  class { 'ff_gln_gw::vpn': }
 
  ff_gln_gw::monitor::nrpe::check_command {
    "openvpn_anonvpn":
      command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C openvpn -a "ovpn-anonvpn"';
  }

  ff_gln_gw::monitor::vnstat::device { 'tun-anonvpn': }

  ff_gln_gw::firewall::forward { 'tun-anonvpn':
    chain => 'mesh'
  }

  # Define Firewall rule for masquerade
  file {
    '/etc/iptables.d/910-Masquerade-tun-anonvpn':
     ensure => file,
     owner => 'root',
     group => 'root',
     mode => '0644',
     content => 'ip4tables -t nat -A POSTROUTING -o tun-anonvpn -j MASQUERADE',
     require => [File['/etc/iptables.d/']];
    '/etc/openvpn/anonvpn-up.sh':
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0755",
      source => "puppet:///modules/ff_gln_gw/etc/openvpn/anonvpn-up.sh",
      require => [Package['openvpn']];
  }
}

#
# generic openvpn profile
#
# Setup an openvpn provfile based on a given directory. The directory
# should provide all needed certificates and configuration. The configuration
# file need to be named "${name}.conf", should be compatible with being
# places in "/etc/openvpn/${name}/" and create an tun device tun-anonvpn.
#
# To be conform with the overall setup the configuration file should also 
# include following lines:
#
# script-security 2
# route-noexec
# up anonvpn-up.sh
#
class ff_gln_gw::vpn::provider::generic (
  $name,   # name of the vpn service
  $config, # src directory with configuration, keys etc.
) {
  include ff_gln_gw::vpn::provider

  file{
    "/etc/openvpn/${name}/":
      ensure => directory,
      owner => "root",
      group => "root",
      mode => "0644",
      source => $config,
      recurse => true,
      require => [Package['openvpn']];
    '/etc/openvpn/anonvpn.conf': 
      ensure => link,
      owner => "root",
      group => "root",
      mode => "0644",
      target => "/etc/openvpn/${name}/${name}.conf",
      require => [File["/etc/openvpn/$name"],
                  Package['openvpn'],
                 ],
      notify => [Service['openvpn']];
  }
}

class ff_gln_gw::vpn::provider::hideio (
  $openvpn_server,
  $openvpn_port,
  $openvpn_user,
  $openvpn_password,
) {
  include ff_gln_gw::vpn::provider

  file { 
    '/etc/openvpn/anonvpn.conf': 
      ensure => link,
      owner => "root",
      group => "root",
      mode => "0644",
      target => "/etc/openvpn/hideio/hideio.conf",
      require => [File["/etc/openvpn/hideio/hideio.conf"],
                  File["/etc/openvpn/hideio/password"],
                  File["/etc/openvpn/hideio/TrustedRoot.pem"],
                  File["/etc/openvpn/anonvpn-up.sh"],
                  Package['openvpn'],
                 ],
      notify => [Service['openvpn']];
    '/etc/openvpn/hideio':
      ensure => directory,
      owner => "root",
      group => "root",
      mode => "0755",
      require => [Package['openvpn']];
    '/etc/openvpn/hideio/hideio.conf': 
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0644",
      content => template("ff_gln_gw/etc/openvpn/hideio.conf.erb"),
      require => [File["/etc/openvpn/hideio"],Package['openvpn']];
    '/etc/openvpn/hideio/password':
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0640",
      content => template("ff_gln_gw/etc/openvpn/password.erb"),
      require => [File['/etc/openvpn/hideio']];
    '/etc/openvpn/hideio/TrustedRoot.pem':
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0644",
      source => "puppet:///modules/ff_gln_gw/etc/openvpn/hideio.root.pem",
      require => [File['/etc/openvpn/hideio']];
  }
}
