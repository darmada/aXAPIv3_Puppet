Puppet::Type.newtype(:axvip) do

	desc 'Custom type for handling A10 vips'

	ensurable

	newparam(:name, :namevar => true) do
	desc 'Common name of the vip'
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
	desc 'Ip address of the vip'
	end
	newparam(:port) do
	desc 'Port of the vip'
	end
	newparam(:type) do
	desc 'Type of the port http|https'
	end
	newparam(:ssltemplate) do
	desc 'Name of the ssl/tls client template to use (should be created in advance)'
	end
	newparam(:natpool) do
	desc 'Name of the nat pool template to use (if omitted no nat pool is used or created)'
	end
        newparam(:startaddress) do
        desc 'Start address of the pool'
        end
        newparam(:endaddress) do
        desc 'Last address of the pool'
        end
        newparam(:netmask) do
        desc 'Netmask of the pool'
        end
        newparam(:group) do
        desc 'Servicegroup to use'
        end
end
