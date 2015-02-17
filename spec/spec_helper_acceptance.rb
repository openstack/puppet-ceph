#
#  Copyright (C) 2015 David Gurtner
#
#  Author: David Gurtner <aldavud@crimson.ch>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require 'minitest'
require 'beaker-rspec'

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  hosts.each do |host|
    install_puppet
    on host, "mkdir -p #{host['distmoduledir']}"
  end

  c.before :suite do
    puppet_module_install(:source => proj_root, :module_name => 'ceph')
    scp_to hosts, File.join(proj_root, 'spec/fixtures/hieradata/hiera.yaml'), '/etc/puppet/hiera.yaml'
    hosts.each do |host|
      # https://tickets.puppetlabs.com/browse/PUP-2566
      on host, 'sed -i "/templatedir/d" /etc/puppet/puppet.conf'
      install_package host, 'git'
      on host, "git clone https://github.com/bodepd/scenario_node_terminus.git #{host['distmoduledir']}/scenario_node_terminus"
      on host, puppet('module install puppetlabs/stdlib --version ">=4.0.0 <5.0.0"'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module install puppetlabs/inifile --version ">=1.0.0 <2.0.0"'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module install puppetlabs/apt --version ">=1.4.0 <2.0.0"'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module install puppetlabs/concat --version ">=1.1.0 <2.0.0"'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module install puppetlabs/apache --version ">=1.0.1 <2.0.0"'), { :acceptable_exit_codes => [0,1] }
      # Flush the firewall
      flushfw = <<-EOS
        iptables -F
        iptables -X
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
      EOS
      on host, flushfw
    end
  end
end
