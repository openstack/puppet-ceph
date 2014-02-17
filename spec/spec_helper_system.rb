#
#  Copyright 2013 Cloudwatt <libre-licensing@cloudwatt.com>
#
#  Author: Loic Dachary <loic@dachary.org>
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

  # Enable colour
  c.tty = true

  c.include RSpecSystemPuppet::Helpers

  c.before :suite do
    [ 'first', 'second' ].each do |vm|
      puppet_install(:node => vm)
      puppet_module_install(:source => proj_root,
                            :module_name => 'ceph',
                            :node => vm)
      shell(:command => 'puppet module install --version 4.1.0 puppetlabs/stdlib',
            :node => vm)
      shell(:command => 'puppet module install --version 1.0.0 puppetlabs/inifile',
            :node => vm)
      shell(:command => 'puppet module install --version 1.4.0 puppetlabs/apt',
            :node => vm)
    end
  end
end
