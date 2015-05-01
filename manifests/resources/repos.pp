class ff_gln_gw::resources::repos (
  $debian_mirror = $ff_gln_gw::params::debian_mirror
) inherits ff_gln_gw::params {
  apt::source { 'repo.universe-factory':
    location   => 'http://repo.universe-factory.net/debian/',
    release    => 'sid',
    repos      => 'main',
    key        => {
      'id'     => '16EF3F64CB201D9C',
      'server' => 'pgpkeys.mit.edu',
    },
    include  => {
      'src' => false,
      'deb' => true,
    }
  }

 apt::source { 'debian.draic.info':
    location    => 'http://debian.draic.info/',
    release     => 'wheezy',
    repos       => 'main',
    include  => {
      'src' => false,
      'deb' => true,
    }
  }

  package { 'debian-keyring':
    ensure => present
  }
  package { 'debian-archive-keyring':
    ensure => present
  }
  apt::source { 'debian-backports':
     location          => $debian_mirror,
     release           => 'wheezy-backports',
     repos             => 'main contrib',
     include  => {
      'src' => false,
      'deb' => true,
     }
  }

  apt::source { 'trusty-backports':
    location => 'http://de.archive.ubuntu.com/ubuntu',
    release => 'trusty-backports',
    repos => 'main universe multiverse restricted',
    key => {
      id => '630239CC130E1A7FD81A27B140976EAF437D05B5',
      server => 'pgp.mit.edu',
    },
  }
}
