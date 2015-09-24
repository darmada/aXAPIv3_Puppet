# Example manifest for creating real servers, service group and vip on AX devices
# Apply to a node that can reach the A10 through https
# For more information run puppet describe on each resource
# Be aware that the providers attempt to save the configuration (e.g. wr mem) but this
# might not work on older versions of the A10 software
# Copyright 2013, A10 Networks provided as is

axvip {'myvip1':
	require => Axsvcgroup['mygroup'],
        axdevice => '10.30.2.68',
        ensure => 'absent',
        password => 'a10',
        username => 'admin',
	ipaddress => '10.12.1.1',
	group => 'mygroup',
	port => '443',
	# ssl client template should exist for type https
	type => 'https',
	ssltemplate => 'SSL-BASIC',
	# if natpool is omitted, no natpool will be created
	natpool => 'mynatpool',
	startaddress => '12.12.12.12',
	netmask => '255.255.255.0',
	endaddress => '12.12.12.12',
}
axvip {'myvip2':
	require => Axsvcgroup['mygroup'],
        axdevice => '10.30.2.68',
        ensure => 'absent',
        password => 'a10',
        username => 'admin',
	ipaddress => '10.12.1.2',
	group => 'mygroup',
	port => '80',
	# ssl client template should exist for type https
	type => 'http',
	# if natpool is omitted, no natpool will be created
	#natpool => 'mynatpool',
	startaddress => '12.12.12.12',
	netmask => '255.255.255.0',
	endaddress => '12.12.12.12',
}

axsvcgroup {'mygroup':
	require => Axserver['myserver1', 'myserver2', 'myserver4', 'myserver3'],
        axdevice => '10.30.2.68',
        ensure => 'absent',
        password => 'a10',
        username => 'admin',
	healthmon => 'ping',
	httpport => '80',
	members => ({ myserver1 => "192.168.0.253", myserver2 => "192.168.0.252", myserver4 => "192.168.0.250", myserver3 => "192.168.0.251" }),
}

axserver {'myserver1':
	axdevice => '10.30.2.68',
	ensure => 'absent',
	httpport => '80',
	ipaddress => '192.168.0.253',
	password => 'a10',
	username => 'admin',
}

axserver {'myserver2':
        axdevice => '10.30.2.68',
        ensure => 'absent',
        httpport => '80',
        ipaddress => '192.168.0.252',
        password => 'a10',
        username => 'admin',
}

axserver {'myserver3':
        axdevice => '10.30.2.68',
        ensure => 'absent',
        httpport => '80',
        ipaddress => '192.168.0.251',
        password => 'a10',
        username => 'admin',
}

axserver {'myserver4':
        axdevice => '10.30.2.68',
        ensure => 'absent',
        httpport => '80',
        ipaddress => '192.168.0.250',
        password => 'a10',
        username => 'admin',
}	

