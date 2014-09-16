define jetty (
  $version,
  $home        = '/opt',
  $manage_user = true,
  $user        = 'jetty',
  $group       = 'jetty',
  $name        = 'jetty',
) {

  include wget
  $pattern_jetty_home_cond = regsubst('^if \[ -z "\$JETTY_HOME" \]\; then', '/', '\\/', 'G', 'U')
  $replacement_jetty_home_cond = regsubst("if [ \"\\\$JETTY_HOME\" ]; then", '/', '\\/', 'G', 'U')

  $pattern_jetty_home = regsubst('^cd "\$JETTY_HOME"', '/', '\\/', 'G', 'U')
  $replacement_jetty_home = regsubst("cd \"${home}/jetty\"", '/', '\\/', 'G', 'U')
  
  $pattern_jetty_pid = regsubst('^  JETTY_PID="\$JETTY_RUN/jetty.pid"', '/', '\\/', 'G', 'U')
  $replacement_jetty_pid = regsubst("  JETTY_PID=\"\\\$JETTY_RUN/${name}.pid\"", '/', '\\/', 'G', 'U')
  $file = "${home}/jetty-distribution-${version}/bin/jetty.sh"

  if $manage_user {

    ensure_resource('user', $user, {
      managehome => true,
      system     => true,
      gid        => $group,
      before     => Exec["jetty_untar_${name}"],
    })

    ensure_resource('group', $group, { 
      ensure => present
    })
  }

  file { "/usr/local/src/${name}":
    ensure => "directory",
  } ->
  file { "${home}":
    ensure => "directory",
  }->
  wget::fetch { "jetty_download_${name}":
    source      => "http://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${version}/jetty-distribution-${version}.tar.gz",
    destination => "/usr/local/src/${name}/jetty-distribution-${version}.tar.gz",
  } ->
  exec { "jetty_untar_${name}":
    command => "tar xf /usr/local/src/${name}/jetty-distribution-${version}.tar.gz && chown -R ${user}:${group} ${home}/jetty-distribution-${version}",
    cwd     => $home,
    creates => "${home}/jetty-distribution-${version}",
    path    => ["/bin",],
    notify  => Service[$name]
  } ->
  
  file { "${home}/jetty":
    ensure => "${home}/jetty-distribution-${version}",
  } ->

  file { "/var/log/${name}":
    ensure => "${home}/${name}/logs",
  } ->

  file { "/etc/default/${name}":
    content => template('jetty/default'),
  } ->

  file { "${file}":
    ensure => present,
  } ->
  exec { "replace JETTY_HOME for ${name} in jetty.sh":
    command => "/usr/bin/perl -pi -e 's/${pattern_jetty_home}/${replacement_jetty_home}/' '${file}'",
    onlyif => "/usr/bin/perl -ne 'BEGIN { \$ret = 1; } \$ret = 0 if /${pattern_jetty_home}/ && ! /\\Q${replacement_jetty_home}\\E/; END { exit \$ret; }' '${file}'",
    alias => "jetty_${name}",
  } ->
  exec { "replace JETTY_PID for ${name}.pid in jetty.sh":
    command => "/usr/bin/perl -pi -e 's/${pattern_jetty_pid}/${replacement_jetty_pid}/' '${file}'",
    onlyif => "/usr/bin/perl -ne 'BEGIN { \$ret = 1; } \$ret = 0 if /${pattern_jetty_pid}/ && ! /\\Q${replacement_jetty_pid}\\E/; END { exit \$ret; }' '${file}'",
    alias => "pid_${name}",
  } ->
  exec { "replace JETTY_HOME conditional for ${name} in jetty.sh":
    command => "/usr/bin/perl -pi -e 's/${pattern_jetty_home_cond}/${replacement_jetty_home_cond}/' '${file}'",
    onlyif => "/usr/bin/perl -ne 'BEGIN { \$ret = 1; } \$ret = 0 if /${pattern_jetty_home_cond}/ && ! /\\Q${replacement_jetty_home_cond}\\E/; END { exit \$ret; }' '${file}'",
  } ->
  file { "/etc/init.d/${name}":
    ensure => "${file}",
  } ~>

  service { $name:
    enable     => true,
    ensure     => running,
    hasstatus  => false,
    hasrestart => true,
  }

}
