require 'puppet'
require 'spec_helper'
require 'puppet/provider/ceph_pool/ceph'

provider_class = Puppet::Type.type(:ceph_pool).provider(:ceph)

describe provider_class do

  describe 'manage pools' do
    let :pool_name do
      'pool1'
    end

    let :pool_attrs do
      {
        :cluster => 'ceph',
        :name    => pool_name,
        :ensure  => 'present',
        :pg_num  => 64,
      }
    end

    let :resource do
      Puppet::Type::Ceph_pool.new(pool_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    describe '#create' do
      context 'with defaults' do
        it 'creates pool' do
          expect(provider_class).to receive(:ceph)
            .with('--cluster', 'ceph', 'osd', 'pool', 'create', pool_name, 64)
          provider.create
        end
      end

      context 'with pgp_num' do
        let :pool_attrs do
          {
            :cluster => 'ceph',
            :name    => pool_name,
            :ensure  => 'present',
            :pg_num  => 64,
            :pgp_num => 32,
          }
        end

        it 'creates pool' do
          expect(provider_class).to receive(:ceph)
            .with('--cluster', 'ceph', 'osd', 'pool', 'create', pool_name, 64, 32)
          provider.create
        end
      end

      context 'with size' do
        let :pool_attrs do
          {
            :cluster => 'ceph',
            :name    => pool_name,
            :ensure  => 'present',
            :pg_num  => 64,
            :size    => 10,
          }
        end

        it 'creates pool' do
          expect(provider_class).to receive(:ceph)
            .with('--cluster', 'ceph', 'osd', 'pool', 'create', pool_name, 64)
          expect(provider_class).to receive(:ceph)
            .with('--cluster', 'ceph', 'osd', 'pool', 'set', pool_name, 'size', 10)
          provider.create
        end
      end

      context 'with application' do
        let :pool_attrs do
          {
            :cluster     => 'ceph',
            :name        => pool_name,
            :ensure      => 'present',
            :pg_num      => 64,
            :application => 'nova',
          }
        end

        it 'creates pool' do
          expect(provider_class).to receive(:ceph)
            .with('--cluster', 'ceph', 'osd', 'pool', 'create', pool_name, 64)
          expect(provider_class).to receive(:ceph)
            .with('--cluster', 'ceph', 'osd', 'pool', 'application', 'enable', pool_name, 'nova')
          provider.create
        end
      end
    end

    describe '#exists?' do
      it 'detects existing pool' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'ls', '-f', 'json')
          .and_return('

["pool1", "pool2"]')
        expect(provider.exists?).to be_truthy
      end
      it 'detects non-eisting pool' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'ls', '-f', 'json')
          .and_return('

["pool2", "pool3"]')
        expect(provider.exists?).to be_falsey
      end
    end

    describe '#destroy' do
      it 'removes pool' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'delete', pool_name, pool_name, '--yes-i-really-really-mean-it')
        provider.destroy
      end
    end

    describe '#size' do
      it 'reads size' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'get', pool_name, 'size', '-f', 'json')
          .and_return("

{\"pool\":\"#{pool_name}\",\"pool_id\":4,\"size\":5}")
        expect(provider.size).to eq(5)
      end
    end

    describe '#size=' do
      it 'sets size' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'set', pool_name, 'size', 10)
        provider.size = 10
      end
    end

    describe '#pg_num' do
      it 'reads pg_num' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'get', pool_name, 'pg_num', '-f', 'json')
          .and_return("

{\"pool\":\"#{pool_name}\",\"pool_id\":4,\"pg_num\":64}")
        expect(provider.pg_num).to eq(64)
      end
    end

    describe '#pg_num=' do
      it 'sets pg_num' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'set', pool_name, 'pg_num', 128)
        provider.pg_num = 128
      end
    end

    describe '#pgp_num' do
      it 'reads pgp_num' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'get', pool_name, 'pgp_num', '-f', 'json')
          .and_return("

{\"pool\":\"#{pool_name}\",\"pool_id\":4,\"pgp_num\":64}")
        expect(provider.pgp_num).to eq(64)
      end
    end

    describe '#pgp_num=' do
      it 'sets pgp_num' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'set', pool_name, 'pgp_num', 128)
        provider.pgp_num = 128
      end
    end

    describe '#application' do
      it 'reads empty application' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'application', 'get', pool_name, '-f', 'json')
          .and_return('

{}')
        expect(provider.application).to eq(nil)
      end
      it 'reads non-empty application' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'application', 'get', pool_name, '-f', 'json')
          .and_return('

{"nova":{}}')
        expect(provider.application).to eq('nova')
      end
    end

    describe '#aplication=' do
      it 'sets application' do
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'application', 'get', pool_name, '-f', 'json')
          .and_return('

{}')
        expect(provider_class).to receive(:ceph)
          .with('--cluster', 'ceph', 'osd', 'pool', 'application', 'enable', pool_name, 'nova')
        provider.application = 'nova'
      end
    end
  end
end
