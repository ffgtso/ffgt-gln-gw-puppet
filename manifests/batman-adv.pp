define ff_gln_gw::batman-adv( $mesh_code
                         , $batman_it = 5000
                         ) {
  include ff_gln_gw::resources::batman-adv
  include ff_gln_gw::firewall

  file {
    "/etc/network/interfaces.d/${mesh_code}-batman.cfg":
    ensure => file,
    content => template('ff_gln_gw/etc/network/mesh-batman.erb'),
    require => [Package['batctl'],Package['batman-adv-dkms']];
  }

  file_line {
   "root_bashrc_bat${mesh_code}":
     path => '/root/.bashrc',
     line => "alias batctl-${mesh_code}='batctl -m bat-${mesh_code}'"
  }

  ff_gln_gw::firewall::device { "bat-${mesh_code}":
    chain => "bat"
  } 
}
