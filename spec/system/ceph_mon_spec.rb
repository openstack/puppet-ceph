#
#  Copyright 2013,2014 Cloudwatt <libre-licensing@cloudwatt.com>
#  Copyright (C) Nine Internet Solutions AG
#
#  Author: Loic Dachary <loic@dachary.org>
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

describe 'ceph::mon' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  mon_host = '$::ipaddress'
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"

  releases.each do |release|

    describe release do
      before(:all) do
        pp = <<-EOS
          class { 'ceph::repo':
            release => '#{release}',
          }
        EOS

        machines.each do |mon|
          puppet_apply(:node => mon, :code => pp) do |r|
            r.exit_code.should_not == 1
          end
        end
      end

      after(:all) do
        pp = <<-EOS
          package { #{packages}:
            ensure => purged
          }
          class { 'ceph::repo':
            release => '#{release}',
            ensure  => absent,
          }
        EOS

        machines.each do |mon|
          puppet_apply(:node => mon, :code => pp) do |r|
            r.exit_code.should_not == 1
          end
        end
      end

      describe 'on one host' do
        it 'should install one monitor' do
          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
              authentication_type => 'none',
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              authentication_type => 'none',
            }
          EOS

          puppet_apply(pp) do |r|
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
          pp = <<-EOS
            ceph::mon { 'a':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          osfamily = facter.facts['osfamily']
          operatingsystem = facter.facts['operatingsystem']

          if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
            shell 'status ceph-mon id=a' do |r|
              r.stdout.should be_empty
              r.stderr.should =~ /Unknown instance: ceph.a/
              r.exit_code.should_not be_zero
            end
          end
          if osfamily == 'RedHat'
            shell 'service ceph status mon.a' do |r|
              r.stdout.should =~ /mon.a not found/
              r.stderr.should be_empty
              r.exit_code.should_not be_zero
            end
          end
        end
      end

      describe 'on one host', :cephx do
        it 'should install one monitor with key' do
          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              key => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end

          shell 'test -z "$(cat /etc/ceph/ceph.client.admin.keyring)"' do |r|
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall one monitor' do
          pp = <<-EOS
            ceph::mon { 'a':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          osfamily = facter.facts['osfamily']
          operatingsystem = facter.facts['operatingsystem']

          if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
            shell 'status ceph-mon id=a' do |r|
              r.stdout.should be_empty
              r.stderr.should =~ /Unknown instance: ceph.a/
              r.exit_code.should_not be_zero
            end
          end
          if osfamily == 'RedHat'
            shell 'service ceph status mon.a' do |r|
              r.stdout.should =~ /mon.a not found/
              r.stderr.should be_empty
              r.exit_code.should_not be_zero
            end
          end
        end

        it 'should install one monitor with keyring' do

          key = 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
          keyring = "[mon.]\\n\\tkey = #{key}\\n\\tcaps mon = \"allow *\""
          keyring_path = "/tmp/keyring"
          shell "echo -e '#{keyring}' > #{keyring_path}"

          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              keyring => '#{keyring_path}',
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end

          shell 'test -f /etc/ceph/ceph.client.admin.keyring' do |r|
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall one monitor' do
          pp = <<-EOS
            ceph::mon { 'a':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          osfamily = facter.facts['osfamily']
          operatingsystem = facter.facts['operatingsystem']

          if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
            shell 'status ceph-mon id=a' do |r|
              r.stdout.should be_empty
              r.stderr.should =~ /Unknown instance: ceph.a/
              r.exit_code.should_not be_zero
            end
          end
          if osfamily == 'RedHat'
            shell 'service ceph status mon.a' do |r|
              r.stdout.should =~ /mon.a not found/
              r.stderr.should be_empty
              r.exit_code.should_not be_zero
            end
          end
        end
      end

      describe 'on two hosts' do
        it 'should be two hosts' do
          machines.size.should == 2
        end

        it 'should install two monitors' do
          machines.each do |mon|
            pp = <<-EOS
                class { 'ceph':
                  fsid => '#{fsid}',
                  mon_host => '10.11.12.2,10.11.12.3',
                  mon_initial_members => 'first,second',
                  public_network => '10.11.12.0/24',
                  authentication_type => 'none',
                }
                ceph::mon { '#{mon}':
                  authentication_type => 'none',
                }
            EOS

            puppet_apply(:node => mon, :code => pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end
          end

          shell 'ceph -s' do |r|
            r.stdout.should =~ /2 mons .* quorum 0,1/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall two monitors' do
          machines.each do |mon|
            pp = <<-EOS
              ceph::mon { '#{mon}':
                ensure => absent,
              }
            EOS

            puppet_apply(:node => mon, :code => pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should == 0
            end

            osfamily = facter.facts['osfamily']
            operatingsystem = facter.facts['operatingsystem']

            if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
              shell "status ceph-mon id=#{mon}" do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /Unknown instance: ceph.#{mon}/
                r.exit_code.should_not be_zero
              end
            end
            if osfamily == 'RedHat'
              shell "service ceph status mon.#{mon}" do |r|
                r.stdout.should =~ /mon.#{mon} not found/
                r.stderr.should be_empty
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
#     cd .rspec_system/vagrant_projects/two-ubuntu-server-1204-x64
#     vagrant destroy --force
#   )
#   cp -a Gemfile-rspec-system Gemfile
#   BUNDLE_PATH=/tmp/vendor bundle install --no-deployment
#   RELEASES=dumpling \
#   RS_DESTROY=no \
#   RS_SET=two-ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system \
#          SPEC=spec/system/ceph_mon_spec.rb \
#          SPEC_OPTS='--tag cephx' &&
#   git checkout Gemfile
# "
# End:
