#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
require 'spec_helper_acceptance'

describe 'basic ceph' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp = <<-EOS
      include openstack_integration
      include openstack_integration::apache
      include openstack_integration::mysql
      include openstack_integration::memcached
      include openstack_integration::keystone
      class { 'openstack_integration::ceph':
        deploy_rgw    => true,
        create_cephfs => true,
      }
      include openstack_integration::repos
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should deploy mon' do
      command('ceph -s') do |r|
        expect(r.exit_code).to eq 0
        expect(r.stdout).to match(/mon: 1 daemons/)
        expect(r.stderr).to be_empty
      end
    end

    it 'should deploy osd' do
      command('ceph osd tree') do |r|
        expect(r.exit_code).to eq 0
        expect(r.stdout).to match(/\s+osd.0\s+up\s+/)
        expect(r.stderr).to be_empty
      end
    end

    it 'should create pools' do
      command('ceph osd pool ls') do |r|
        expect(r.exit_code).to eq 0
        expect(r.stdout).to match(/^nova$/)
        expect(r.stdout).to match(/^glance$/)
        expect(r.stdout).to match(/^cephfs_data$/)
        expect(r.stdout).to match(/^cephfs_metadata$/)
        expect(r.stderr).to be_empty
      end
    end

    it 'should create fs' do
      command('ceph fs ls') do |r|
        expect(r.exit_code).to eq 0
        expect(r.stdout).to match(/^cephfs$/)
        expect(r.stderr).to be_empty
      end
    end

    describe port(8080) do
      it { is_expected.to be_listening }
    end
  end
end
