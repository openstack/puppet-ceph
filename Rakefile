require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
begin
  require 'rspec-system/rake_task'
rescue LoadError => e
  warn e.message
  warn "Run `gem install rspec-system-puppet` to enable integration tests."
end

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_parameter_defaults')