class duplicity::packages {
  # Install the packages
  ensure_packages (['duplicity', 'python-boto', 'gnupg'])

  # Install the log directory.  stdout ends up here stderr is
  # free to get mailed out by cron
  file { '/var/log/duplicity':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0770',
  }
}
