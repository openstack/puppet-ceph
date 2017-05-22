Facter.add('ceph_daemons') do
	setcode do
		if File.exist? '/var/run/ceph/'
      		daemons = Facter::Core::Execution.exec('/bin/find /var/run/ceph -name "*.asok" -exec basename {} .asok \; | sort')
      		rval = daemons.split("\n")
      		rval.join(',')
    	else
    		''
    	end
    end
end