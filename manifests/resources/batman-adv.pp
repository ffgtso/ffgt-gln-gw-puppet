class ff_gln_gw::resources::batman-adv () {
  if ($ff_gln_gw::params::batman_compat == "14") {
    include ff_gln_gw::resources::repos

    Class[ff_gln_gw::resources::repos]
    ->
    package {
      'batctl': ensure => '2013.4.0-1'; # installed;
      'batman-adv-dkms': ensure => installed;
    }
  } else {
    package {
      'batctl': ensure => 'latest'; # installed;
      'batman-adv-dkms': ensure => absent;
    }
  }
}
