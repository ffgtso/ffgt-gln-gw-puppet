class ff_gln_gw::alfred (
  $master = false
) { 
  vcsrepo { '/opt/alfred':
    ensure => present,
    provider => git,
    source => "http://git.open-mesh.org/alfred.git";
  } ->
  exec { 'patch-makefile':
    command => "/bin/sed -i -e 's/export CONFIG_ALFRED_CAPABILITIES=y/export CONFIG_ALFRED_CAPABILITIES=n/g' Makefile",
    cwd => "/opt/alfred/",
    require => [Package['build-essential'],Package['pkg-config'],Package['libgps-dev']];
  }

  file { '/etc/init.d/alfred':
    ensure => file,
    mode => "0755",
    source => "puppet:///modules/ff_gln_gw/etc/init.d/alfred";
  }

  file { '/usr/local/bin/alfred-announce':
    ensure => file,
    mode => "0755",
    source => "puppet:///modules/ff_gln_gw/usr/local/bin/alfred-announce";
  }

  package { 
    'build-essential':
      ensure => installed;
    'pkg-config':
      ensure => installed;
    'libgps-dev':
      ensure => installed;
    'python3':
      ensure => installed;
    'ethtool':
      ensure => installed;
  }

  exec { 'alfred':
    command => "/usr/bin/make",
    cwd => "/opt/alfred/",
    require => [Vcsrepo['/opt/alfred'],Package['build-essential'],Package['pkg-config'],Package['libgps-dev']];
  }

  service { 'alfred':
    ensure => running,
    hasrestart => true,
    enable => true,
    require => [Exec['alfred'],File['/etc/init.d/alfred']];
   }

  vcsrepo { '/opt/alfred-announce':
    ensure => present,
    provider => git,
    source => "https://github.com/ffnord/ffnord-gateway-alfred.git",
    require => [Package['python3'],Package['ethtool']];
  }

  cron {
   'update-alfred-announce':
     command => 'PATH=/opt/alfred/:/bin:/usr/bin:/sbin:$PATH /usr/local/bin/alfred-announce',
     user    => root,
     minute  => '*',
     require => [Vcsrepo['/opt/alfred-announce'], Vcsrepo['/opt/alfred'],File['/usr/local/bin/alfred-announce']];
  }
  
  ff_gln_gw::firewall::service { 'alfred':
    protos => ["udp"],
    chains => ["mesh","bat"],
    ports => ['16962'],
  }

  if $master {
    ff_gln_gw::resources::ff_gln_gw::field { "ALFRED_OPTS": value => '-m'; }
  } else {
    ff_gln_gw::resources::ff_gln_gw::field { "ALFRED_OPTS": value => ''; }
  }
}
