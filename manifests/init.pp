# Specifically targetting CentOS 5.8 with this class.

class ozone::ozone ( $user = "ozone", $ozone_home = "/opt/ozone", $ozone_https_port = 443, $ozone_http_port = 80){


    if !defined(Service["iptables"]) {
  	  service { "iptables": ensure => false, enable => false }
    }

    user { "$user":
        ensure => 'present',
        home => "/home/$user",
        shell => '/bin/bash',
        groups => 'wheel'
    } ->
    file { "/home/$user": 
        ensure => 'directory',
        owner => $user,
        group => $user,
        mode => 770
    } ->
    file { "/home/$user/projects": 
        ensure => directory,
        owner => $user,
        group => $user } ->
    file { "$ozone_home":
        ensure => 'directory',
        owner => $user,
        group => $user,
        mode => 775 
    } ->     
    file { "/var/run/ozone/":
        ensure => 'directory',
        owner => $user,
        group => $user,
        mode => 775
    } 
    

    package{ "unzip": ensure => installed } ->
    package { "java-1.6.0-openjdk-devel": ensure => installed } ->
    # Need Ant from source here
    exec { "get_ant": 
        cwd => '/usr/local',
        command => 'wget http://download.nextag.com/apache//ant/binaries/apache-ant-1.9.2-bin.zip',
        creates => '/usr/local/apache-ant-1.9.2-bin.zip',
    } ->
    exec { "unzip_ant":
        cwd => '/usr/local',
        command => 'unzip apache-ant-1.9.2-bin.zip',
        creates => '/usr/local/apache-ant-1.9.2'
    } -> 
    file { "/usr/local/bin/ant":
        ensure => link,
        target => '/usr/local/apache-ant-1.9.2/bin/ant'
    } ->
    exec { "get_ozone":
        cwd => $ozone_home,
        command => "wget https://s3.amazonaws.com/org.ozoneplatform/OWF/7-GA/OWF-bundle-7-GA.zip",
        creates => "$ozone_home/OWF-bundle-7-GA.zip"
    } -> 
    exec { "unzip_ozone":
        user => $user,
        cwd => $ozone_home,
        command => "unzip OWF-bundle-7-GA.zip",
        creates => "$ozone_home/apache-tomcat-7.0.21",
    } ->
    file { "$ozone_home/tomcat":
        owner => $user,
        group => $user,
        ensure => "link",
        target => "$ozone_home/apache-tomcat-7.0.21",
    } ->
    file { "$ozone_home/tomcat/bin/catalina.sh":
        owner => $user,
        group => $user,
        mode => "755"
    } ->
    file { "$ozone_home/tomcat/conf/server.xml":
        owner => $user,
        group => $user,
        mode => 755,
        content => template("ozone/server.xml.erb"),
    } ->
    file { "/etc/init.d/ozone":
        owner => 'root',
        group => 'root',
        mode => 755,
        content => template("ozone/ozone.erb"),
    } ->
    file { "$ozone_home/tomcat/webapps/ozone":
        owner => $user,
        group => $user,
        ensure => 'directory',
    } ->
    service { "ozone": 
        enable => true,
        ensure => running
    }
}
