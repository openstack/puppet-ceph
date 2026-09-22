require 'spec_helper'

describe 'ceph::keys' do
  let (:pre_condition) do
    "class { 'ceph': fsid => 'foo' }"
  end

  shared_examples 'ceph::keys' do
    context 'with default params' do
      it { should_not contain_ceph__key('client.admin') }
    end

    context 'with keys' do
      let :params do
        {
          :args => {
            'client.admin' => {
              'secret'  => 'AQBMGHJTkC8HKhAAJ7NH255wYypgm1oVuV41MA==',
              'cap_mon' => 'allow *',
            },
            'client.volumes' => {
              'secret'       => sensitive('AQA4MPZTOGU0ARAAXH9a0fXxVq0X25n2yPREDw=='),
              'keyring_path' => '/etc/ceph/ceph.client.volumes.keyring',
            },
          },
          :defaults => {
            'inject' => true,
          },
        }
      end

      it 'should pass the secrets on as sensitive values' do
        should contain_ceph__key('client.admin').with(
          :secret  => sensitive('AQBMGHJTkC8HKhAAJ7NH255wYypgm1oVuV41MA=='),
          :cap_mon => 'allow *',
          :inject  => true,
        )
        should contain_ceph__key('client.volumes').with(
          :secret       => sensitive('AQA4MPZTOGU0ARAAXH9a0fXxVq0X25n2yPREDw=='),
          :keyring_path => '/etc/ceph/ceph.client.volumes.keyring',
          :inject       => true,
        )
      end
    end

    context 'with a key without secret' do
      let :params do
        {
          :args => {
            'client.admin' => {
              'cap_mon' => 'allow *',
            },
          },
        }
      end

      it { should raise_error(Puppet::Error, /expects a value for parameter 'secret'/) }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::keys'
    end
  end
end
