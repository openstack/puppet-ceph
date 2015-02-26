#
#  Copyright (C) Nine Internet Solutions AG
#
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
require 'spec_helper_system'

describe 'ceph::mons' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  # passing it directly as unqoted array is not supported everywhere
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  mon_key = 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  fixture_path = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures'))
  data = File.join(fixture_path, 'data/data')
  snt_data = File.join(fixture_path, 'scenario_node_terminus/data')
  data_path = '/etc/puppet/data'
  hiera_config = File.join(fixture_path, 'data/hiera.yaml')
  snt_hiera_config = File.join(fixture_path, 'scenario_node_terminus/hiera.yaml')
  hiera_config_file = '/etc/puppet/hiera.yaml'
  user_hiera_file = '/etc/puppet/data/hiera_data/user.yaml'
  user_params_file = '/etc/puppet/data/global_hiera_params/user.yaml'
  minimal_hiera_config = <<-EOS
---
:logger: noop
  EOS
  data_site_pp = <<-'EOS'
$role = mon
if ! $::role {
  $role = regsubst($::clientcert, '([a-zA-Z]+)[^a-zA-Z].*', '\1')
}

$scenario = hiera('scenario', "")
$auth_type = hiera('auth_type', "")
$ensure = hiera('ensure', "")

node default {
  notice("my scenario is ${scenario}")
  notice("my role is ${role}")
  # Should be defined in scenario/[name_of_scenario]/[name_of_role].yaml
  $node_class_groups = hiera_array('class_groups', undef)
  notice("class groups: ${node_class_groups}")
  if $node_class_groups {
    class_group { $node_class_groups: }
  }

  $node_classes = hiera_array('classes', undef)
  if $node_classes {
    include $node_classes
    notify { " Including node classes : ${node_classes}": }
  }
}

define class_group {
  include hiera($name)
  notice($name)
  $x = hiera($name)
  notice( "including ${x}" )
}
  EOS

  describe 'data' do
    before(:all) do
      machines.each do |vm|
        rcp(:sp => data, :dp => data_path, :d => node(:name => vm))
        rcp(:sp => hiera_config, :dp => hiera_config_file, :d => node(:name => vm))
      end
    end

    after(:all) do
      machines.each do |vm|
        file = Tempfile.new('hieraconfig')
        begin
          file.write(minimal_hiera_config)
          file.close
          rcp(:sp => file.path, :dp => hiera_config_file, :d => node(:name => vm))
        ensure
          file.unlink
        end

        shell(:node => vm, :command => 'rm -rf /etc/puppet/data')
      end
    end

    releases.each do |release|
      describe release do
        describe 'on one host' do
          it 'should install one monitor' do
            file = Tempfile.new('user_hiera_data')
            begin
              file.write(<<-EOS)
---
release: #{release}
fsid: '#{fsid}'

# Global Hiera Params:
scenario: 2_role
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_hiera_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply(data_site_pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end

            shell 'ceph -s' do |r|
              r.stdout.should =~ /1 mons at/
              r.stderr.should be_empty
              r.exit_code.should be_zero
            end
          end

          it 'should uninstall one monitor' do
            file = Tempfile.new('user_hiera_data')
            begin
              file.write(<<-EOS)
release: #{release}

# Global Hiera Params:
ensure: purged
scenario: 2_role
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_hiera_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply(data_site_pp) do |r|
              r.exit_code.should_not == 1
            end

            osfamily = facter.facts['osfamily']
            operatingsystem = facter.facts['operatingsystem']

            if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
              shell 'status ceph-mon id=first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /status: Unknown job: ceph-mon/
                r.exit_code.should_not be_zero
              end
            end
            if osfamily == 'RedHat'
              shell 'service ceph status mon.first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /ceph: unrecognized service/
                r.exit_code.should_not be_zero
              end
            end
          end
        end

        describe 'on one host', :cephx do
          it 'should install one monitor' do
            file = Tempfile.new('user_hiera_data')
            begin
              file.write(<<-EOS)
---
release: #{release}
fsid: '#{fsid}'
mon_key: '#{mon_key}'

# Global Hiera Params:
scenario: 2_role
auth_type: cephx

#################
# Data Mappings #
#################

ceph::keys::args:
  'client.admin':
    secret: '#{admin_key}'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: allow
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_hiera_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply(data_site_pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end

            shell 'cat /etc/ceph/ceph.client.admin.keyring' do |r|
              r.stdout.should =~ /#{admin_key}/
              r.stderr.should be_empty
              r.exit_code.should be_zero
            end

            shell 'ceph -s' do |r|
              r.stdout.should =~ /1 mons at/
              r.stderr.should be_empty
              r.exit_code.should be_zero
            end

            shell 'ceph auth list' do |r|
              r.stdout.should =~ /#{admin_key}/
              r.exit_code.should be_zero
            end
          end

          it 'should uninstall one monitor' do
            file = Tempfile.new('user_hiera_data')
            begin
              file.write(<<-EOS)
---
release: #{release}

# Global Hiera Params:
ensure: purged
scenario: 2_role
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_hiera_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply(data_site_pp) do |r|
              r.exit_code.should_not == 1
            end

            osfamily = facter.facts['osfamily']
            operatingsystem = facter.facts['operatingsystem']

            if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
              shell 'status ceph-mon id=first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /status: Unknown job: ceph-mon/
                r.exit_code.should_not be_zero
              end
            end
            if osfamily == 'RedHat'
              shell 'service ceph status mon.first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /ceph: unrecognized service/
                r.exit_code.should_not be_zero
              end
            end
          end
        end
      end
    end
  end

  describe 'scenario_node_terminus' do
    before(:all) do
      pp = <<-EOS
      ini_setting { 'puppetmastermodulepath':
        ensure  => present,
        path    => '/etc/puppet/puppet.conf',
        section => 'main',
        setting => 'node_terminus',
        value   => 'scenario',
      }
      EOS

      machines.each do |vm|
        puppet_apply(:node => vm, :code => pp) do |r|
          r.exit_code.should_not == 1
        end

        rcp(:sp => snt_data, :dp => data_path, :d => node(:name => vm))
        rcp(:sp => snt_hiera_config, :dp => hiera_config_file, :d => node(:name => vm))
      end
    end

    after(:all) do
      machines.each do |vm|
        file = Tempfile.new('hieraconfig')
        begin
          file.write(minimal_hiera_config)
          file.close
          rcp(:sp => file.path, :dp => hiera_config_file, :d => node(:name => vm))
        ensure
          file.unlink
        end

        shell(:node => vm, :command => "sed -i '/^\\s*node_terminus\\s*=\\s*scenario\\s*$/d' /etc/puppet/puppet.conf")
        shell(:node => vm, :command => 'rm -rf /etc/puppet/data')
      end
    end

    releases.each do |release|
      describe release do
        describe 'on one host' do
          it 'should install one monitor' do
            file = Tempfile.new('user_hiera_data')
            begin
              file.write(<<-EOS)
fsid: '#{fsid}'
release: #{release}
EOS
file.close
rcp(:sp => file.path, :dp => user_hiera_file, :d => node)
            ensure
              file.unlink
            end

            file = Tempfile.new('user_params')
            begin
              file.write(<<-EOS)
ensure: present
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_params_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply('') do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end

            shell 'ceph -s' do |r|
              r.stdout.should =~ /1 mons at/
                r.stderr.should be_empty
              r.exit_code.should be_zero
            end
          end

          it 'should uninstall one monitor' do
            file = Tempfile.new('user_params')
            begin
              file.write(<<-EOS)
ensure: purged
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_params_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply('') do |r|
              r.exit_code.should_not == 1
            end

            osfamily = facter.facts['osfamily']
            operatingsystem = facter.facts['operatingsystem']

            if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
              shell 'status ceph-mon id=first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /status: Unknown job: ceph-mon/
                  r.exit_code.should_not be_zero
              end
            end
            if osfamily == 'RedHat'
              shell 'service ceph status mon.first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /ceph: unrecognized service/
                  r.exit_code.should_not be_zero
              end
            end
          end
        end

        describe 'on one host', :cephx do
          it 'should install one monitor' do
            file = Tempfile.new('user_hiera_data')
            begin
              file.write(<<-EOS)
---
fsid: '#{fsid}'
release: #{release}
ceph::keys::args:
  'client.admin':
    secret: '#{admin_key}'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: allow
EOS
file.close
rcp(:sp => file.path, :dp => user_hiera_file, :d => node)
            ensure
              file.unlink
            end

            file = Tempfile.new('user_params')
            begin
              file.write(<<-EOS)
auth_type: cephx
ensure: present
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_params_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply('') do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end

            shell 'cat /etc/ceph/ceph.client.admin.keyring' do |r|
              r.stdout.should =~ /#{admin_key}/
                r.stderr.should be_empty
              r.exit_code.should be_zero
            end

            shell 'ceph -s' do |r|
              r.stdout.should =~ /1 mons at/
                r.stderr.should be_empty
              r.exit_code.should be_zero
            end

            shell 'ceph auth list' do |r|
              r.stdout.should =~ /#{admin_key}/
                r.exit_code.should be_zero
            end
          end

          it 'should uninstall one monitor' do
            file = Tempfile.new('user_params')
            begin
              file.write(<<-EOS)
ensure: purged
              EOS
              file.close
              rcp(:sp => file.path, :dp => user_params_file, :d => node)
            ensure
              file.unlink
            end

            puppet_apply('') do |r|
              r.exit_code.should_not == 1
            end

            osfamily = facter.facts['osfamily']
            operatingsystem = facter.facts['operatingsystem']

            if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
              shell 'status ceph-mon id=first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /status: Unknown job: ceph-mon/
                  r.exit_code.should_not be_zero
              end
            end
            if osfamily == 'RedHat'
              shell 'service ceph status mon.first' do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /ceph: unrecognized service/
                  r.exit_code.should_not be_zero
              end
            end
          end
        end
      end
    end
  end
end
# Local Variables:
# compile-command: "cd ../..
#   (
#     cd .rspec_system/vagrant_projects/ubuntu-server-1204-x64
#     vagrant destroy --force
#   )
#   cp -a Gemfile-rspec-system Gemfile
#   BUNDLE_PATH=/tmp/vendor bundle install --no-deployment
#   RELEASES=dumpling \
#   MACHINES=first \
#   RS_DESTROY=no \
#   RS_SET=ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system \
#         SPEC=spec/system/ceph_mons_spec.rb \
#         SPEC_OPTS='--tag cephx' | tee /tmp/puppet.log &&
#   git checkout Gemfile
# "
# End:
