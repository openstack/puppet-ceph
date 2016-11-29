# Load libraries from openstacklib here to simulate how they live together in a real puppet run (for provider unit tests)
$LOAD_PATH.push(File.join(File.dirname(__FILE__), 'fixtures', 'modules', 'openstacklib', 'lib'))
require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'
require 'puppet-openstack_spec_helper/facts'

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
  fixture_path = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))

  c.hiera_config = File.join(fixture_path, 'hieradata/hiera.yaml')

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

at_exit { RSpec::Puppet::Coverage.report! }
