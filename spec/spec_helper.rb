#
#   Copyright (C) 2014 Nine Internet Solutions AG
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
# Author: David Gurtner <aldavud@crimson.ch>
#
require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |c|
  fixture_path = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))

  c.hiera_config = File.join(fixture_path, 'hieradata/hiera.yaml')

  c.alias_it_should_behave_like_to(:it_configures, 'configures')

  c.before(:all) do
    data = YAML.load_file(c.hiera_config)
    data[:yaml][:datadir] = File.join(fixture_path, 'hieradata')
    File.open(c.hiera_config, 'w') do |f|
      f.write data.to_yaml
    end
  end

  c.after(:all) do
    `git checkout -- #{c.hiera_config}`
  end
end
