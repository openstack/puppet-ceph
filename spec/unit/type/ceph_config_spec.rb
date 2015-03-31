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

require 'puppet'
require 'puppet/type/ceph_config'

describe 'Puppet::Type.type(:ceph_config)' do

  before :each do
    @ceph_config = Puppet::Type.type(:ceph_config).new(
      :name => 'global/ceph_is_foo', :value => 'bar')
  end

  it 'should work bascily' do
    @ceph_config[:value] = 'max'
    expect(@ceph_config[:value]).to eq('max')
  end

  it 'should convert true to True' do
    @ceph_config[:value] = 'tRuE'
    expect(@ceph_config[:value]).to eq('True')
  end

  it 'should convert false to False' do
    @ceph_config[:value] = 'fAlSe'
    expect(@ceph_config[:value]).to eq('False')
  end
end