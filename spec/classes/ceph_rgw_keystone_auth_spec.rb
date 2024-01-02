require 'spec_helper'

describe 'ceph::rgw::keystone::auth' do

  shared_examples 'ceph::rgw::keystone::auth' do
    let :params do
      {
        :password => 'rgw_password',
        :user     => 'rgw_user',
        :tenant   => 'services'
      }
    end

    it {
      should contain_class('openstacklib::openstackclient')
      should contain_keystone__resource__service_identity('rgw').with(
        :configure_user      => true,
        :configure_endpoint  => true,
        :configure_user_role => true,
        :service_name        => 'swift',
        :service_type        => 'object-store',
        :service_description => 'Ceph RGW Service',
        :region              => 'RegionOne',
        :auth_name           => 'rgw_user',
        :password            => 'rgw_password',
        :email               => 'rgwuser@localhost',
        :tenant              => 'services',
        :roles               => ['admin'],
        :public_url          => 'http://127.0.0.1:8080/swift/v1',
        :admin_url           => 'http://127.0.0.1:8080/swift/v1',
        :internal_url        => 'http://127.0.0.1:8080/swift/v1',
      )
    }
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::rgw::keystone::auth'
    end
  end

end
