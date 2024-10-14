require 'puppet'
require 'puppet/type/ceph_pool'

describe 'Puppet::Type.type(:neutron_subnet)' do
  it 'should not allow non-positive values' do
    expect{Puppet::Type.type(:ceph_pool).new(
      :name   => 'pool1',
      :pg_num => 0,
    )}.to raise_error(Puppet::ResourceError)
    expect{Puppet::Type.type(:ceph_pool).new(
      :name    => 'pool1',
      :pgp_num => 0,
    )}.to raise_error(Puppet::ResourceError)
    expect{Puppet::Type.type(:ceph_pool).new(
      :name => 'pool1',
      :size => 0,
    )}.to raise_error(Puppet::ResourceError)
  end

  it 'should not allow non-integer values' do
    expect{Puppet::Type.type(:ceph_pool).new(
      :name   => 'pool1',
      :pg_num => '64',
    )}.to raise_error(Puppet::ResourceError)
    expect{Puppet::Type.type(:ceph_pool).new(
      :name    => 'pool1',
      :pgp_num => '64',
    )}.to raise_error(Puppet::ResourceError)
    expect{Puppet::Type.type(:ceph_pool).new(
      :name => 'pool1',
      :size => '123',
    )}.to raise_error(Puppet::ResourceError)
  end

  it 'should not allow pgp_num > pg_num' do
    expect{Puppet::Type.type(:ceph_pool).new(
      :name    => 'pool1',
      :pg_num  => 64,
      :pgp_num => 65,
    )}.to raise_error(Puppet::ResourceError)
  end
end

