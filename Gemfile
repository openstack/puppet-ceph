source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper', :require => false
  gem 'rspec-puppet', '~> 2.0.0', :require => false
  gem 'beaker-rspec', '~> 2.2.4', :require => false
  gem 'puppet-lint-param-docs'
  gem 'metadata-json-lint'
  gem 'puppet-lint-absolute_classname-check'
  gem 'puppet-lint-absolute_template_path'
  gem 'puppet-lint-trailing_newline-check'

  # Puppet 4.x related lint checks
  gem 'puppet-lint-unquoted_string-check'
  gem 'puppet-lint-leading_zero-check'
  gem 'puppet-lint-variable_contains_upcase'
  gem 'puppet-lint-numericvariable'

  gem 'json'
  gem 'webmock'
  gem 'minitest', :require => false
  gem 'test', :require => false
  gem 'test-unit', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
