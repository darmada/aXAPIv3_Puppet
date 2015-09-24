Puppet::Type.newtype(:axsvcgroup) do

        desc 'Custom type for handling A10 servicegroups'

        ensurable

        newparam(:name, :namevar => true) do
        desc 'Common name of the servicegroup'
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
        newparam(:members) do
        desc 'Members of the servicegroup (type Hash)'
        end
        newparam(:httpport) do
        desc 'Port of the real servers'
        end
        newparam(:healthmon) do
        desc 'Healthmonitor to use for the servicegroup'
        end
end
