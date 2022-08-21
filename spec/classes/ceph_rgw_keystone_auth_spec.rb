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
      should contain_keystone_service('swift::object-store').with(
        :ensure      => 'present',
        :description => 'Ceph RGW Service',
      )
      should contain_keystone_endpoint('RegionOne/swift::object-store').with(
        :ensure       => 'present',
        :public_url   => 'http://127.0.0.1:8080/swift/v1',
        :admin_url    => 'http://127.0.0.1:8080/swift/v1',
        :internal_url => 'http://127.0.0.1:8080/swift/v1',
      )
      should contain_keystone_user('rgw_user').with(
        :ensure   => 'present',
        :password => 'rgw_password',
        :email    => 'rgwuser@localhost',
      )
      should contain_keystone_role('admin').with(
        :ensure => 'present',
      )
      should contain_keystone_role('Member').with(
        :ensure => 'present',
      )
      should contain_keystone_user_role('rgw_user@services').with(
        :ensure => 'present',
        :roles  => ['admin', 'Member'],
      )
    }
  end

  on_supported_os.each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::rgw::keystone::auth'
    end
  end

end
