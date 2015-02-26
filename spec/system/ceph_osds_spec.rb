#
#  Copyright (C) 2014 Nine Internet Solutions AG
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

describe 'ceph::osds' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  # passing it directly as unqoted array is not supported everywhere
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  bootstrap_osd_key = 'AQCVio9T+BD9HBAAuSh15WdZYJOrSwnU/cbJsg=='
  fixture_path = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures'))
  data = File.join(fixture_path, 'scenario_node_terminus/data')
  data_path = '/etc/puppet/data'
  config_file = data_path + '/config.yaml'
  role_mappings_file = data_path + '/role_mappings.yaml'
  hiera_config = File.join(fixture_path, 'scenario_node_terminus/hiera.yaml')
  hiera_config_file = '/etc/puppet/hiera.yaml'
  user_hiera_file = data_path + '/hiera_data/user.yaml'
  user_params_file = data_path + '/global_hiera_params/user.yaml'
  minimal_hiera_config = <<-EOS
---
:logger: noop
  EOS

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

      rcp(:sp => data, :dp => data_path, :d => node(:name => vm))
      rcp(:sp => hiera_config, :dp => hiera_config_file, :d => node(:name => vm))

      file = Tempfile.new('config')
      begin
        file.write(<<-EOS)
scenario: allinone
        EOS
        file.close
        rcp(:sp => file.path, :dp => config_file, :d => node)
      ensure
        file.unlink
      end
      file = Tempfile.new('role_mappings')
      begin
        file.write(<<-EOS)
first: allinone
second: osd
        EOS
        file.close
        rcp(:sp => file.path, :dp => role_mappings_file, :d => node)
      ensure
        file.unlink
      end
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
      after(:each) do
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

        machines.each do |vm|
          puppet_apply('') do |r|
            r.exit_code.should_not == 1
          end

          shell(:node => vm, :command => 'test -b /dev/sdb && sgdisk --zap-all --clear --mbrtogpt -- /dev/sdb')
          shell(:node => vm, :command => 'rm -rf /var/lib/ceph; rm -rf /etc/ceph')
        end
      end

      describe 'on one host' do
        it 'should install one OSD' do
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

          shell 'ceph osd tree' do |r|
            r.stdout.should =~ /osd.0/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end
      end

      describe 'on one host', :cephx do
        it 'should install one OSD' do
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
  'client.bootstrap-osd':
    secret: '#{bootstrap_osd_key}'
    cap_mon: 'allow profile bootstrap-osd'
    keyring_path: '/var/lib/ceph/bootstrap-osd/ceph.keyring'
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

          shell 'ceph osd tree' do |r|
            r.stdout.should =~ /osd.0/
            r.stderr.should be_empty
            r.exit_code.should be_zero
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
#         SPEC=spec/system/ceph_osds_spec.rb \
#         SPEC_OPTS='--tag cephx' | tee /tmp/puppet.log &&
#   git checkout Gemfile
# "
# End:
