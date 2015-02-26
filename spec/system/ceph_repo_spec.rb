#
#  Copyright (C) 2013,2014 Cloudwatt <libre.licensing@cloudwatt.com>
#  Copyright 2014 (C) Nine Internet Solutions AG
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

describe 'ceph::repo' do

  release2version = {
    'dumpling' => '0.67',
    'firefly' => '0.80',
    'giant' => '0.87',
    '(default)' => '0.87',
  }

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : release2version.keys

  # on RedHat family we need to remove with the correct release,
  # and at this point we do not know what is currently installed
  it 'should remove repo independent of release' do
    releases.each do |release|

      release_arg = release == '(default)' ? '' : "release => '#{release}',"
      pp = <<-EOS
        class { 'ceph::repo':
          #{release_arg}
          ensure  => absent,
          extras  => true,
          fastcgi => true,
        }
      EOS

      puppet_apply(pp) do |r|
        r.exit_code.should_not == 1
      end
    end

    osfamily = facter.facts['osfamily']

    if osfamily == 'Debian'
      shell 'apt-cache policy ceph' do |r|
        r.stdout.should_not =~ /ceph.com/
        r.stderr.should be_empty
        r.exit_code.should be_zero
      end
      shell 'apt-cache policy curl' do |r|
        r.stdout.should_not =~ /ceph.com/
        r.exit_code.should be_zero
      end
      shell 'apt-cache policy libapache2-mod-fastcgi' do |r|
        r.stdout.should_not =~ /ceph.com/
        r.exit_code.should be_zero
      end
    end
    if osfamily == 'RedHat'
      shell 'yum info ceph' do |r|
        r.stdout.should_not =~ /ceph.com/
        r.stderr.should =~ /Error: No matching Packages to list/
        r.exit_code.should_not be_zero
      end
      shell 'yum info qemu-kvm' do |r|
        r.stdout.should_not =~ /Repo.*ext-ceph-extras/
        r.exit_code.should be_zero
      end
      shell 'yum info mod_fastcgi' do |r|
        r.stdout.should_not =~ /Repo.*ext-ceph-fastcgi/
        r.stderr.should =~ /Error: No matching Packages to list/
        r.exit_code.should_not be_zero
      end
    end
  end

  releases.each do |release|

    release_arg = release == '(default)' ? '' : "release => '#{release}',"

    describe release do

      version = release2version[release]

      it "should find #{version}" do
        osfamily = facter.facts['osfamily']

        osfamily2querycommand = {
          'Debian' => 'apt-cache policy ceph',
          'RedHat' => 'yum info ceph',
        }
        osfamily2queryresult = {
          'Debian' => "Candidate: #{version}" ,
          'RedHat' => "Version     : #{version}",
        }

        querycommand = osfamily2querycommand[osfamily]
        queryresult = osfamily2queryresult[osfamily]

        pp = <<-EOS
          class { 'ceph::repo':
            #{release_arg}
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell querycommand do |r|
          r.stdout.should =~ /#{queryresult}/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

        # Test extras is not enabled
        if osfamily == 'Debian'
          shell 'apt-cache policy curl' do |r|
            r.stdout.should_not =~ /ceph\.com.*ceph-extras/
            r.exit_code.should be_zero
          end
        end
        if osfamily == 'RedHat'
          shell 'yum info qemu-kvm' do |r|
            r.stdout.should_not =~ /Repo.*ext-ceph-extras/
            r.exit_code.should be_zero
          end
        end

        # On RedHat family we need to use the version when removing
        pp = <<-EOS
          class { 'ceph::repo':
            ensure  => absent,
            #{release_arg}
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        if osfamily == 'Debian'
          shell querycommand do |r|
            r.stdout.should_not =~ /ceph.com/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end
        if osfamily == 'RedHat'
          shell querycommand do |r|
            r.stdout.should_not =~ /ceph.com/
            r.stderr.should =~ /Error: No matching Packages to list/
            r.exit_code.should_not be_zero
          end
        end
      end

      it "should find curl/qemu-kvm in ceph-extras" do
        osfamily = facter.facts['osfamily']

        pp = <<-EOS
          class { 'ceph::repo':
            #{release_arg}
            extras => true,
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        # Test for a package in ceph-extras (curl/qemu-kvm)
        if osfamily == 'Debian'
          shell 'apt-cache policy curl' do |r|
            r.stdout.should =~ /ceph\.com.*ceph-extras/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end
        if osfamily == 'RedHat'
          shell 'yum info qemu-kvm' do |r|
            r.stdout.should =~ /Repo.*ext-ceph-extras/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end

        # On RedHat family we need to use the version when removing
        pp = <<-EOS
          class { 'ceph::repo':
            ensure => absent,
            extras => true,
            #{release_arg}
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        if osfamily == 'Debian'
          shell 'apt-cache policy curl' do |r|
            r.stdout.should_not =~ /ceph.com/
            r.exit_code.should be_zero
          end
        end
        if osfamily == 'RedHat'
          shell 'yum info qemu-kvm' do |r|
            r.stdout.should_not =~ /Repo.*ext-ceph-extras/
            r.exit_code.should be_zero
          end
        end
      end

      it "should find fastcgi in ceph-fastcgi" do
        osfamily = facter.facts['osfamily']

        pp = <<-EOS
          class { 'ceph::repo':
            #{release_arg}
            fastcgi => true,
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        # Test fastcgi in ceph-fastcgi
        if osfamily == 'Debian'
          shell 'apt-cache policy libapache2-mod-fastcgi' do |r|
            r.stdout.should =~ /ceph.com/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end
        if osfamily == 'RedHat'
          shell 'yum info mod_fastcgi' do |r|
            r.stdout.should =~ /Repo.*ext-ceph-fastcgi/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end

        # On RedHat family we need to use the version when removing
        pp = <<-EOS
          class { 'ceph::repo':
            ensure  => absent,
            fastcgi => true,
            #{release_arg}
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        if osfamily == 'Debian'
          shell 'apt-cache policy libapache2-mod-fastcgi' do |r|
            r.stdout.should_not =~ /ceph.com/
            r.exit_code.should be_zero
          end
        end
        if osfamily == 'RedHat'
          shell 'yum info mod_fastcgi' do |r|
            r.stdout.should_not =~ /Repo.*ext-ceph-fastcgi/
            r.stderr.should =~ /Error: No matching Packages to list/
            r.exit_code.should_not be_zero
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
#   RS_DESTROY=no \
#   RS_SET=ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_repo_spec.rb &&
#   git checkout Gemfile
# "
# End:
