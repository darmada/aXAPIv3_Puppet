Puppet::Type.newtype(:axserver) do

	desc 'Custom type for handling A10 real servers'

	ensurable

	newparam(:name, :namevar => true) do
	desc 'Common name of the real server'
	end
	newparam(:axdevice) do
	desc 'Name or ip address  of the A10 device to configure'
	end
	newparam(:username) do
	desc 'Username for the A10 device'
	end
	newparam(:password) do
	desc 'Password for the A10 device'
	end
	newparam(:ipaddress) do
	desc 'Ip address of the real server'
	end
	newparam(:httpport) do
	desc 'Port of the real server'
	end
end
