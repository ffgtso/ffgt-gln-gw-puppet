class ff_gln_gw::etckeeper {

  # Ensure the gitignore file exists befor we put our own lines into it
  file {
    '/etc/.gitignore':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0600';
  } ->

  # Ensure that we do not track the ff_gln_gw module
  file_line {
    'etckeeper_puppet':
       path => '/etc/.gitignore',
       line => 'puppet/modules/ff_gln_gw/';
    'etckeeper_dotfiles':
       path => '/etc/.gitignore',
       line => '.*';
    'etckepper_unignore_etckeeper':
       path => '/etc/.gitignore',
       line => '!.etckeeper';
  } ->

  package {
    'etckeeper':
       ensure => installed;
  }
}

# Create an gitignore entry for given path
define ff_gln_gw::etckeeper::ignore {
  if defined(Class['ff_gln_gw::etckeeper']) {
    validate_absolute_path($name)
    # Does path $name begin with '/etc/'
    if $name =~ /^\/etc\// {
      $ignore = regsubst($name,'^/etc/(.*)$','\1')
      file_line {
        "etckeeper_${name}":
          path => '/etc/.gitignore',
          line => $ignore,
          before => Package['etckeeper'];
      }
    }
  }
}
