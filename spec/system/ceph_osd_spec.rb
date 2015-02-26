#
#  Copyright 2014 Cloudwatt <libre.licensing@cloudwatt.com>
#  Copyright (C) 2014 Nine Internet Solutions AG
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

describe 'ceph::osd' do

  datas = ENV['DATAS'] ? ENV['DATAS'].split : [ '/dev/sdb', '/srv/data' ]
  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  mon_host = '$::ipaddress'
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"

  purge = <<-EOS
    ceph::mon { 'a': ensure => absent }
    ->
    file { [
       '/var/lib/ceph/bootstrap-osd/ceph.keyring',
       '/etc/ceph/ceph.client.admin.keyring',
      ]:
      ensure => absent
    }
    ->
    package { #{packages}:
      ensure => purged
    }
  EOS

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

      datas.each do |data|
        it 'should install one OSD no cephx' do
          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
              authentication_type => 'none',
            }
            ceph_config {
             'global/osd_journal_size': value => '100';
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              authentication_type => 'none',
            }
            ceph::osd { '#{data}': }
          EOS

          puppet_apply(pp) do |r|
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

        it 'should uninstall one osd' do
          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should_not be_zero
          end

          pp = <<-EOS
            ceph::osd { '#{data}':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should be_zero
          end
          shell "test -b #{data} && ceph-disk zap #{data}"
        end

        it 'should uninstall one monitor and all packages' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should install one osd with cephx' do

          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
            }
            ceph_config {
             'global/osd_journal_size': value => '100';
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              key => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
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
            exec { 'bootstrap-key':
              command => '/usr/sbin/ceph-create-keys --id a',
            }
            ->
            ceph::osd { '#{data}': }
          EOS

          puppet_apply(pp) do |r|
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

        it 'should uninstall one osd' do
          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should_not be_zero
          end

          pp = <<-EOS
            ceph::osd { '#{data}': ensure => absent, }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should be_zero
          end

          shell "test -b #{data} && ceph-disk zap #{data}"
        end

        it 'should uninstall one monitor and all packages' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should install one osd with external journal and no cephx' do
          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
              authentication_type => 'none',
            }
            ceph_config {
             'global/osd_journal_size': value => '100';
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              key => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
              authentication_type => 'none',
            }
            ceph::osd { '#{data}':
              journal => '/tmp/journal'
            }
          EOS

          puppet_apply(pp) do |r|
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

        it 'should uninstall one osd and external journal' do
          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should_not be_zero
          end

          pp = <<-EOS
            ceph::osd { '#{data}': ensure => absent, }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should be_zero
          end
          shell "test -b #{data} && ceph-disk zap #{data}"
        end

        it 'should uninstall one monitor and all packages' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should install one OSD no cephx on a partition' do
          shell 'sgdisk --largest-new=1 --change-name="1:ceph data" --partition-guid=1:7aebb13f-d4a5-4b94-8622-355d2b5401f1 --typecode=1:4fbd7e29-9d25-41b8-afd0-062c0ceff05d -- /dev/sdb' do |r|
            r.exit_code.should be_zero
          end

          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
              authentication_type => 'none',
            }
            ceph_config {
             'global/osd_journal_size': value => '100';
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              authentication_type => 'none',
            }
            ceph::osd { '/dev/sdb1': }
          EOS

          puppet_apply(pp) do |r|
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

        it 'should uninstall one osd' do
          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should_not be_zero
          end

          pp = <<-EOS
            ceph::osd { '/dev/sdb1':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should be_zero
          end
          shell 'ceph-disk zap /dev/sdb'
        end

        it 'should install one OSD no cephx on partition and activate after umount' do
          shell 'sgdisk --delete=1 /dev/sdb || true; sgdisk --largest-new=1 --change-name="1:ceph data" --partition-guid=1:7aebb13f-d4a5-4b94-8622-355d2b5401f1 --typecode=1:4fbd7e29-9d25-41b8-afd0-062c0ceff05d -- /dev/sdb' do |r|
            r.exit_code.should be_zero
          end

          pp = <<-EOS
            class { 'ceph':
              fsid => '#{fsid}',
              mon_host => #{mon_host},
              authentication_type => 'none',
            }
            ceph_config {
             'global/osd_journal_size': value => '100';
            }
            ceph::mon { 'a':
              public_addr => #{mon_host},
              authentication_type => 'none',
            }
            ceph::osd { '/dev/sdb1': }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end

          shell 'ceph osd tree' do |r|
            r.stdout.should =~ /osd.0/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

          # stop and umount (but leave it prepared)
          shell 'stop ceph-osd id=0 || /etc/init.d/ceph stop osd.0; umount /dev/sdb1' do |r|
            r.exit_code.should be_zero
          end

          # rerun puppet (should activate but not prepare)
          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end

          # check osd up and same osd.id
          shell 'ceph osd tree' do |r|
            r.stdout.should =~ /osd.0\s*up/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

        end

        it 'should uninstall one osd' do
          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should_not be_zero
          end

          pp = <<-EOS
            ceph::osd { '/dev/sdb1':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should == 0
          end

          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should be_zero
          end
          shell 'ceph-disk zap /dev/sdb'
        end

        it 'should uninstall one monitor and all packages' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
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
#   MACHINES=first \
#   RELEASES=dumpling \
#   DATAS=/srv/data \
#   RS_DESTROY=no \
#   RS_SET=ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_osd_spec.rb &&
#   git checkout Gemfile
# "
# End:
