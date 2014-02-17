#
#  Copyright 2013 Cloudwatt <libre-licensing@cloudwatt.com>
#
#  Author: Loic Dachary <loic@dachary.org>
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

  releases = [ 'cuttlefish', 'dumpling', 'emperor' ]
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'

#  ['emperor'].each do |release|
  releases.each do |release|
    describe release do
      it 'should install one monitor with cephx and key' do
        pp = <<-EOS
          class { 'ceph::repo':
            release => '#{release}',
          }
          ->
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
          }
          ->
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            key => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
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
        end

        shell 'status ceph-mon id=a' do |r|
          r.stdout.should be_empty
          r.stderr.should =~ /Unknown instance: ceph.a/
          r.exit_code.should_not be_zero
        end
      end
    end
  end

#  [].each do |release|
  releases.each do |release|
    describe release do
      it 'should install one monitor with cephx and keyring' do

        key = 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
        keyring = "[mon.]\\n\\tkey = ${key}\\n\\tcaps mon = \"allow *\""
        keyring_path = "/tmp/keyring"
        shell "echo -e '${keyring}' > ${keyring_path}"

        pp = <<-EOS
          class { 'ceph::repo':
            release => '#{release}',
          }
          ->
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
          }
          ->
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            keyring => '${keyring_path}',
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
        end

        shell 'status ceph-mon id=a' do |r|
          r.stdout.should be_empty
          r.stderr.should =~ /Unknown instance: ceph.a/
          r.exit_code.should_not be_zero
        end
      end
    end
  end

#  [].each do |release|
  releases.each do |release|
    describe release do
      it 'should install one monitor no cephx' do
        pp = <<-EOS
          class { 'ceph::repo':
            release => '#{release}',
          }
          ->
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
            authentication_type => 'none',
          }
          ->
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
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
        end

        shell 'status ceph-mon id=a' do |r|
          r.stdout.should be_empty
          r.stderr.should =~ /Unknown instance: ceph.a/
          r.exit_code.should_not be_zero
        end
      end
    end
  end

#  [].each do |release|
  releases.each do |release|
    describe release do
      it 'should install two monitors, two hosts, no cephx' do
        [ 'first', 'second' ].each do |mon|
          pp = <<-EOS
              class { 'ceph::repo':
                release => '#{release}',
              }
              ->
              class { 'ceph':
                fsid => '#{fsid}',
                mon_host => '10.11.12.2,10.11.12.3',
                public_network => '10.11.12.0/24',
                authentication_type => 'none',
              }
              ->
              ceph::mon { '#{mon}':
                authentication_type => 'none',
              }
          EOS

          puppet_apply(:node => "#{mon}", :code => pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end
        end

        shell 'ceph -s' do |r|
          r.stdout.should =~ /2 mons .* quorum 0,1 first,second/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should uninstall two monitors' do
        [ 'first', 'second' ].each do |mon|
          pp = <<-EOS
            ceph::mon { '#{mon}':
              ensure => absent,
            }
          EOS

          puppet_apply(:node => "#{mon}", :code => pp) do |r|
            r.exit_code.should_not == 1
          end

          shell "status ceph-mon id=#{mon}" do |r|
            r.stdout.should be_empty
            r.stderr.should =~ /Unknown instance: ceph.#{mon}/
            r.exit_code.should_not be_zero
          end
        end
      end
    end
  end

end
