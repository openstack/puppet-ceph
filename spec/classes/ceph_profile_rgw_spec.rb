require 'spec_helper'

describe 'ceph::profile::rgw' do

  shared_examples 'ceph profile rgw' do

    it { should contain_ceph__rgw('radosgw.gateway').with(
      :user          => 'ceph',
      :frontend_type => 'beast',
      :rgw_frontends => 'beast endpoint=127.0.0.1:8080',
      :rgw_swift_url => 'http://127.0.0.1:8080',
    ) }
    it { should contain_ceph__rgw__keystone('radosgw.gateway').with(
      :rgw_keystone_admin_domain   => 'Default',
      :rgw_keystone_admin_project  => 'services',
      :rgw_keystone_admin_user     => 'rgwuser',
      :rgw_keystone_admin_password => 'secret',
      :rgw_keystone_url            => 'http://127.0.0.1:5000'
    ) }
    it { should contain_class('ceph::rgw::keystone::auth').with(
      :password     => 'secret',
      :user         => 'rgwuser',
      :tenant       => 'services',
      :public_url   => 'http://127.0.0.1:8080/swift/v1',
      :admin_url    => 'http://127.0.0.1:8080/swift/v1',
      :internal_url => 'http://127.0.0.1:8080/swift/v1',
    ) }
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph profile rgw'
    end
  end
end
