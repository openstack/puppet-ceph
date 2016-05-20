#
#  Copyright (C) 2016 Keith Schincke
#
#  Author: Keith Schincke <kschinck@redhat.com>
#  forked from:
#  Author: David Gurtner <aldavud@crimson.ch>
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
require 'spec_helper_acceptance'

describe 'ceph rgw/civetweb' do

  release = 'hammer'
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  mon_key ='AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  radosgw_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRwg=='
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"

  keystone_admin_token = 'keystonetoken'
  keystone_password = '123456'

  test_user = 'testuser'
  test_password = '123456'
  test_email = 'testuser@example.com'
  test_tenant = 'openstack'

  describe 'ceph::rgw::civetweb' do

    it 'should install one monitor/osd with a rgw/civetweb' do
      pp = <<-EOS
        $user = 'root'

        case $::osfamily {
          'Debian': {
            include ::apt
            apt::source { 'cloudarchive-kilo':
              location          => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
              release           => 'trusty-updates/kilo',
              repos             => 'main',
              include_src       => false,
              required_packages => 'ubuntu-cloud-keyring',
            }
            package { 'python-tz':
              ensure => latest,
            }
          }
          'RedHat': {
            # ceph-radosgw expects open file limit of 32768
            file { '/etc/security/limits.d/80-nofile.conf':
              content => '*          hard    nofile     32768',
            }
            yumrepo { 'openstack-kilo':
              descr    => 'OpenStack Kilo Repository',
              baseurl  => 'http://mirror.centos.org/centos/7/cloud/x86_64/openstack-kilo/',
              enabled  => '1',
              gpgcheck => '0',
              gpgkey   => 'https://raw.githubusercontent.com/redhat-openstack/rdo-release/kilo/RPM-GPG-KEY-CentOS-SIG-Cloud',
              priority => '15', # prefer over EPEL, but below ceph
            }
          }
          default: {
            fail ("Unsupported OS family ${::osfamily}")
          }
        }

        # ceph setup
        class { 'ceph::repo':
          ensure  => present,
          release => '#{release}',
        }
        ->
        class { 'ceph':
          fsid                      => '#{fsid}',
          mon_host                  => $::ipaddress,
          mon_initial_members       => 'a',
          osd_pool_default_size     => '1',
          osd_pool_default_min_size => '1',
        }
        ceph::mon { 'a':
          public_addr => $::ipaddress,
          key         => '#{mon_key}',
        }
        ceph::key { 'client.admin':
          secret         => '#{admin_key}',
          cap_mon        => 'allow *',
          cap_osd        => 'allow *',
          cap_mds        => 'allow *',
          inject         => true,
          inject_as_id   => 'mon.',
          inject_keyring => '/var/lib/ceph/mon/ceph-a/keyring',
        }
        ->
        ceph::key { 'client.radosgw.gateway':
          user    => $user,
          secret  => '#{radosgw_key}',
          cap_mon => 'allow rwx',
          cap_osd => 'allow rwx',
          inject  => true,
        }
        ->
        exec { 'bootstrap-key':
          command => '/usr/sbin/ceph-create-keys --id a',
        }
        ->
        ceph::osd { '/srv/data': }

        # setup ceph radosgw
        host { $::fqdn: # workaround for bad 'hostname -f' in vagrant box
          ip           => $ipaddress,
          host_aliases => [$::hostname],
        }
        ->
        file { '/var/run/ceph': # workaround for bad sysvinit script (ignores socket)
          ensure => directory,
          owner  => $user,
        }
        ->
        ceph::rgw { 'radosgw.gateway':
          user          => $user,
          frontend_type => 'civetweb',
          rgw_frontends => 'civetweb port=80',
        }
        Ceph::Osd['/srv/data'] -> Service['radosgw-radosgw.gateway']

        package { 'python-swiftclient':  # required for tests below
          ensure => present,
        }
        ceph_config {
          'global/mon_data_avail_warn': value => 10; # workaround for health warn in mon
          'global/osd_journal_size':    value => 100;
        }

      EOS

      osfamily = fact 'osfamily'

      servicequery = {
        'Debian' => 'status radosgw id=radosgw.gateway',
        'RedHat' => 'service ceph-radosgw status id=radosgw.gateway',
      }

      apply_manifest(pp, :catch_failures => true)

      shell servicequery[osfamily] do |r|
        expect(r.exit_code).to be_zero
      end

      shell "/usr/bin/radosgw-admin user create --uid=#{test_user} --email=#{test_email} --secret=#{test_password} --display-name=\"Test User\"" do |r|
        expect(r.exit_code).to be_zero
      end

      shell "/usr/bin/radosgw-admin subuser create --uid=#{test_user} --subuser=#{test_user}:swift --access=full" do |r|
        expect(r.exit_code).to be_zero
      end

      shell "/usr/bin/radosgw-admin key create --subuser=#{test_user}:swift --key-type=swift --secret=#{test_password}" do |r|
        expect(r.exit_code).to be_zero
      end

      shell "curl -i -H 'X-Auth-User: #{test_user}:swift' -H 'X-Auth-Key: #{test_password}' http://127.0.0.1:80/auth/v1.0/" do |r|
        expect(r.exit_code).to be_zero
        expect(r.stdout).to match(/HTTP\/1\.1 204 No Content/)
        expect(r.stdout).not_to match(/401 Unauthorized/)
      end
    end

    it 'should configure keystone and ceph-rgw' do
      pp = <<-EOS
        $user = 'root'
        class { 'ceph::repo':
          release => '#{release}',
          fastcgi => false,
        } 
        class { 'ceph':
          fsid                       => '#{fsid}',
          mon_host                   => $::ipaddress,
          mon_initial_members        => 'a',
          osd_pool_default_size      => '1',
          osd_pool_default_min_size  => '1',
        }
        ceph::rgw { 'radosgw.gateway':
          user            => $user,
          frontend_type => 'civetweb',
          rgw_frontends => 'civetweb port=80',
        }

        case $::osfamily {
          'Debian': {
            #trusty ships with pbr 0.7
            #openstackclient.shell raises an requiring pbr!=0.7,<1.0,>=0.6'
            #the latest is 0.10
            package { 'python-pbr':
              ensure => 'latest',
            }
            include ::apt
            apt::source { 'cloudarchive-kilo':
              location => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
              release  => 'trusty-updates/kilo',
              repos    => 'main',
              include  => {
                'src'  => 'false',
              },
            }
            package { 'ubuntu-cloud-keyring':
              ensure => present,
            }
            package { 'python-tz':
              ensure => latest,
            }
            Apt::Source['cloudarchive-kilo'] -> Package['ubuntu-cloud-keyring']
            #Package['ubuntu-cloud-keyring'] -> Package['keystone','python-swiftclient']
            #Exec['apt_update'] -> Package['keystone','python-swiftclient']
            #xec['apt_update'] -> Package['keystone']
          }
          'RedHat': {
            yumrepo { 'openstack-kilo':
              descr    => 'OpenStack Kilo Repository',
              baseurl  => 'http://mirror.centos.org/centos/7/cloud/x86_64/openstack-kilo/',
              enabled  => '1',
              gpgcheck => '0',
              gpgkey   => 'https://raw.githubusercontent.com/redhat-openstack/rdo-release/kilo/RPM-GPG-KEY-CentOS-SIG-Cloud',
              priority => '15', # prefer over EPEL, but below ceph
            }
            Yumrepo<||> -> Package['keystone']
          }
        }

        class { 'keystone':
          verbose             => true,
          catalog_type        => 'sql',
          admin_token         => '#{keystone_admin_token}',
          admin_endpoint      => "http://${::ipaddress}:35357",
        }
        ->
        class { 'keystone::roles::admin':
          email        => 'admin@example.com',
          password     => '#{keystone_password}',
        }
        ->
        class { 'keystone::endpoint':
          public_url   => "http://${::ipaddress}:5000",
          admin_url    => "http://${::ipaddress}:35357",
          internal_url => "http://${::ipaddress}:5000",
          region       => 'example-1',
        }
        Service['keystone'] -> Ceph::Rgw::Keystone['radosgw.gateway']

        keystone_service { 'swift':
          ensure      => present,
          type        => 'object-store',
          description => 'Openstack Object Storage Service',
        }
        Keystone_service<||> -> Ceph::Rgw::Keystone['radosgw.gateway']
        keystone_endpoint { 'example-1/swift':
          ensure       => present,
          public_url   => "http://${::fqdn}:8080/swift/v1",
          admin_url    => "http://${::fqdn}:8080/swift/v1",
          internal_url => "http://${::fqdn}:8080/swift/v1",
        }
        Keystone_endpoint<||> -> Ceph::Rgw::Keystone['radosgw.gateway']

        keystone_user { '#{test_user}':
          ensure   => present,
          enabled  => true,
          email    => '#{test_email}',
          password => '#{test_password}',
          tenant   => '#{test_tenant}',
        }
        Keystone_user<||> -> Ceph::Rgw::Keystone['radosgw.gateway']
        keystone_user_role { 'testuser@openstack':
          ensure => present,
          roles  => ['_member_'],
        }
        Keystone_user_role<||> -> Ceph::Rgw::Keystone['radosgw.gateway']

        #wget is used by ceph::rgw::keystone to pull down files
        package { 'wget':  # required for tests below
          ensure => present,
        } ->
        ceph::rgw::keystone { 'radosgw.gateway':
          rgw_keystone_url         => "http://${::ipaddress}:5000",
          rgw_keystone_admin_token => '#{keystone_admin_token}',
          rgw_keystone_version     => "v2.0",
          user                     => $user,
        }
      EOS

      osfamily = fact 'osfamily'

      servicequery = {
        'Debian' => 'status radosgw id=radosgw.gateway',
        'RedHat' => 'service ceph-radosgw status id=radosgw.gateway',
      }

      apply_manifest(pp, :catch_failures => true)
      shell servicequery[osfamily] do |r|
        expect(r.exit_code).to be_zero
      end

      shell "curl -i -H 'X-Auth-User: #{test_user}:swift' -H 'X-Auth-Key: #{test_password}' http://127.0.0.1:80/auth/v1.0/" do |r|
        expect(r.exit_code).to be_zero
        expect(r.stdout).to match(/HTTP\/1\.1 204 No Content/)
        expect(r.stdout).not_to match(/401 Unauthorized/)
      end

    end

    it 'should purge everything' do
      purge = <<-EOS
        case $::osfamily {
          'Debian': {
            $radosgw = 'radosgw'
            include ::apt
            apt::source { 'cloudarchive-kilo':
               ensure  => absent,
            }
          }
          'RedHat': {
            $radosgw = 'ceph-radosgw'
             yumrepo { 'openstack-kilo':
               ensure  => absent,
             }
          }
        }
        ceph::osd { '/srv/data':
          ensure => absent,
        }
        ->
        ceph::mon { 'a': ensure => absent }
        ->
        file { [
          '/var/lib/ceph/bootstrap-osd/ceph.keyring',
          '/var/lib/ceph/bootstrap-mds/ceph.keyring',
          '/var/lib/ceph/nss/cert8.db',
          '/var/lib/ceph/nss/key3.db',
          '/var/lib/ceph/nss/secmod.db',
          '/var/lib/ceph/radosgw/ceph-radosgw.gateway',
          '/var/lib/ceph/radosgw',
          '/var/lib/ceph/nss',
          '/etc/ceph/ceph.client.admin.keyring',
          '/etc/ceph/ceph.client.radosgw.gateway',
          '/var/lib/ceph',
          '/srv/data',
          ]:
          ensure => absent,
          recurse => true,
          purge => true,
          force => true,
        }
        ->
        package { $radosgw: ensure => purged }
        ->
        package { #{packages}:
          ensure => purged
        }
        class { 'ceph::repo':
          ensure  => absent,
          release => '#{release}',
          fastcgi => false,
        }
      EOS

      osfamily = fact 'osfamily'

      apply_manifest(purge, :catch_failures => true)
    end
  end
end
# Local Variables:
# compile-command: "cd ../..
#   BUNDLE_PATH=/tmp/vendor bundle install
#   BEAKER_set=ubuntu-server-1404-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rspec spec/acceptance/ceph_usecases_spec.rb
# "
# End:
