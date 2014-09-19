class duplicity::packages {
  # Install the packages
  package {[
            'duplicity',
            'python-paramiko',
            'python-gobject-2',
            'python-boto',
            'gnupg'
            ]:
          ensure => present
  }
}
