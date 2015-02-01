#
#  Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
#  Copyright (C) 2014 Nine Internet Solutions AG
#
#  Author: Loic Dachary <loic@dachary.org>
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
require 'rspec-system/spec_helper'
require 'rspec-system-puppet/helpers'

include RSpecSystemPuppet::Helpers

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Enable color
  c.tty = true

  c.include RSpecSystemPuppet::Helpers

  c.before :suite do
    machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
    machines.each do |vm|
      puppet_install(:node => vm)
      # https://tickets.puppetlabs.com/browse/PUP-2566
      shell(:command => 'sed -i "/templatedir/d" /etc/puppet/puppet.conf',
            :node => vm)
      puppet_module_install(:source => proj_root,
                            :module_name => 'ceph',
                            :node => vm)
      puppet_module_install(:source => File.join(proj_root, '../scenario_node_terminus'),
                            :module_name => 'scenario_node_terminus',
                            :node => vm)
      shell(:command => 'puppet module install --version 4.x puppetlabs/stdlib',
            :node => vm)
      shell(:command => 'puppet module install --version 1.0.0 puppetlabs/inifile',
            :node => vm)
      shell(:command => 'puppet module install --version 1.4.0 puppetlabs/apt',
            :node => vm)
      shell(:command => 'puppet module install --version 1.1.x puppetlabs/concat',
            :node => vm)
      shell(:command => 'puppet module install --version 1.0.1 puppetlabs/apache',
            :node => vm)
      rcp(:sp => File.join(proj_root, 'spec/fixtures/hieradata/hiera.yaml'),
          :dp => '/etc/puppet/hiera.yaml',
          :d => node(:name => vm))
      # Flush the firewall
      flushfw = <<-EOS
        iptables -F
        iptables -X
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
      EOS
      shell(:node => vm, :command => flushfw)
    end
  end
end
