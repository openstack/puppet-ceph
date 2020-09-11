#
#  Copyright (C) 2015 David Gurtner
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
require 'spec_helper_acceptance'

describe 'ceph mon osd' do

  context 'default parameters' do

    it 'should install one monitor and one OSD on /srv/data' do
      pp = <<-EOS
        class { 'ceph::repo':
          enable_sig  => true,
          enable_epel => false,
          ceph_mirror => $ceph_mirror,
        }
        class { 'ceph':
          fsid                         => '82274746-9a2c-426b-8c51-107fb0d890c6',
          mon_host                     => $::ipaddress,
          authentication_type          => 'none',
          osd_pool_default_size        => '1',
          osd_pool_default_min_size    => '1',
          osd_max_object_namespace_len => '64',
          osd_max_object_name_len      => '256',
        }
        ceph_config {
         'global/osd_journal_size':             value => '100';
        }
        ceph::mgr { 'a':
          authentication_type => 'none',
        }
        ceph::mon { 'a':
          public_addr         => $::ipaddress,
          authentication_type => 'none',
        }
        ceph::osd { '/srv/data': }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)

      if os[:family].casecmp('RedHat') == 0
        describe command('sleep 10') do
          its(:exit_status) { should eq 0 }
        end

        describe command('ceph -s') do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should match /mon: 1 daemons/) }
          its(:stderr) { should be_empty }
        end

        describe command('ceph osd tree | grep osd.0') do
          its(:exit_status) { should eq 0 }
          its(:stdout) { should match /up/ }
          its(:stderr) { should be_empty }
      end
    end
  end

end
