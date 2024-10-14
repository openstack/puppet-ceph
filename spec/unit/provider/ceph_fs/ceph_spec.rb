require 'puppet'
require 'spec_helper'
require 'puppet/provider/ceph_fs/ceph'

provider_class = Puppet::Type.type(:ceph_fs).provider(:ceph)

describe provider_class do

  describe 'manage fss' do
    let :fs_name do
      'fs1'
    end

    let :fs_attrs do
      {
        :cluster            => 'ceph',
        :name               => fs_name,
        :data_pool_name     => 'data',
        :metadata_pool_name => 'metadata',
      }
    end

    let :resource do
      Puppet::Type::Ceph_fs.new(fs_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    describe '#create' do
      context 'with defaults' do
        it 'creates fs' do
          expect(provider_class).to receive(:ceph)
            .with('--cluster', 'ceph', 'fs', 'new', fs_name, 'metadata', 'data')
          provider.create
        end
      end
    end

    describe '#exists?' do
      it 'detects existing fs' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'fs', 'ls', '-f', 'json')
          .and_return('

[{"name":"fs1","metadata_pool":"metadata","metadata_pool_id":5,"data_pool_ids":[6],"data_pools":["data"]}]')
        expect(provider.exists?).to be_truthy
      end
      it 'detects non-eisting fs' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'fs', 'ls', '-f', 'json')
          .and_return('

[{"name":"fs2","metadata_pool":"metadata","metadata_pool_id":5,"data_pool_ids":[6],"data_pools":["data"]}]')
        expect(provider.exists?).to be_falsey
      end
    end

    describe '#destroy' do
      it 'removes fs' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'fs', 'rm', fs_name, '--yes-i-really-really-mean-it')
        provider.destroy
      end
    end

    describe '#data_pool' do
      it 'reads data_pool' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'fs', 'ls', '-f', 'json')
          .and_return('

[{"name":"fs1","metadata_pool":"metadata","metadata_pool_id":5,"data_pool_ids":[6],"data_pools":["data"]}]')
        expect(provider.data_pool_name).to eq('data')
      end
    end

    describe '#metadata_pool' do
      it 'reads metadata_pool' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'fs', 'ls', '-f', 'json')
          .and_return('

[{"name":"fs1","metadata_pool":"metadata","metadata_pool_id":5,"data_pool_ids":[6],"data_pools":["data"]}]')
        expect(provider.metadata_pool_name).to eq('metadata')
      end
    end
  end
end
