source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :development, :test, :system_tests do
  gem 'puppet-openstack_spec_helper',
      :git     => 'https://git.openstack.org/openstack/puppet-openstack_spec_helper',
      :branch  => 'stable/mitaka',
      :require => false
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, :require => false
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
