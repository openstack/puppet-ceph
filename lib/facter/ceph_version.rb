Facter.add('cephmajor') do
	setcode do
		if File.exist? '/usr/bin/ceph'
      		Facter::Core::Execution.exec('/usr/bin/ceph --version | egrep -o "[0-9]+\.[0-9]+\.[0-9]\s" | awk -F. \'{print $1}\'')
    	else
    		0
    	end
    end
end


Facter.add('cephminor') do
	setcode do
		if File.exist? '/usr/bin/ceph'
			Facter::Core::Execution.exec('/usr/bin/ceph --version | egrep -o "[0-9]+\.[0-9]+\.[0-9]\s" | awk -F. \'{print $2}\'')
		else
			0
		end
	end
end
