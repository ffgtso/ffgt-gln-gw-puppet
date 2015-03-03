class ff_gln_gw::monitor::munin ( $host
                             , $muninserver = "0.0.0.0"
                             , $default_interface = "eth0"
                             ) {
  include ff_gln_gw::monitor::vnstat
 
  package { 'munin-node' : ensure => installed; }
  -> Package['vnstat']
  -> ff_gln_gw::monitor::vnstat::device { "${default_interface}": }
  -> file { 
       '/etc/munin/munin-node.conf': ensure => file, content => template('ff_gln_gw/etc/munin/munin-node.conf.erb'); 
       '/usr/share/munin/plugins/vnstat_': ensure => file, mode => '0755', source => 'puppet:///modules/ff_gln_gw/usr/share/munin/plugins/vnstat_';
       '/etc/munin/plugins/vnstat_eth0_monthly_rxtx': ensure => link, target => '/usr/share/munin/plugins/vnstat_';
       '/usr/share/munin/plugins/udp-statistics': ensure => file, mode => '0755', source => 'puppet:///modules/ff_gln_gw/usr/share/munin/plugins/udp-statistics';
       '/etc/munin/plugins/udp-statistics': ensure => link, target => '/usr/share/munin/plugins/udp-statistics';
# TODO: delete not needed plugins
       '/etc/munin/plugin-conf.d/vnstat': ensure => file, content => '[vnstat_eth0_monthly_rxtx]
env.estimate 1';
  } -> service { 'munin-node': ensure => running, hasrestart => true, enable => true; } 
}
