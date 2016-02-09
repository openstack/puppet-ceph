#   Copyright (C) 2013 Mirantis Inc.
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
# Author: Andrew Woodward <xarses>

# This is aparently one of the few ways to do this load
# see https://github.com/openstack/puppet-nova/blob/master/spec/unit/provider/nova_config/ini_setting_spec.rb
$LOAD_PATH.push(
  File.join(
    File.dirname(__FILE__),
    '..',
    '..',
    '..',
    'fixtures',
    'modules',
    'inifile',
    'lib')
)

require 'spec_helper'
require 'puppet'

provider_class = Puppet::Type.type(:ceph_config).provider(:ini_setting)

describe provider_class do
  include PuppetlabsSpec::Files

  let(:tmpfile) { tmpfilename("ceph_config_test") }

  let(:params) { {
      :path    => tmpfile,
  } }

  def validate(expected)
    expect(File.read(tmpfile)).to eq(expected)
  end

  it 'should create keys = value and ensure space around equals' do
    resource = Puppet::Type::Ceph_config.new(params.merge(
      :name => 'global/ceph_is_foo', :value => 'bar'))
    provider = provider_class.new(resource)
    expect(provider.exists?).to be_falsey
    provider.create
    expect(provider.exists?).to be_truthy
    validate(<<-EOS

[global]
ceph_is_foo = bar
    EOS
    )
  end

  it 'should default to file_path if param path is not passed' do
    resource = Puppet::Type::Ceph_config.new(
      :name => 'global/ceph_is_foo', :value => 'bar')
    provider = provider_class.new(resource)
    expect(provider.file_path).to eq('/etc/ceph/ceph.conf')
  end

end
