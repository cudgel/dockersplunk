class { 'splunk':
  type              => 'standalone',
  create_user       => true,
  version           => '8.0.4.1',
  release           => 'ab7a85abaa98',
}

