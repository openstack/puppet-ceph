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
        if $::operatingsystem == 'CentOS' {
          class { 'ceph::repo':
            release     => 'jewel',
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
          ceph::mon { 'a':
            public_addr         => $::ipaddress,
            authentication_type => 'none',
          }
          ceph::osd { '/srv/data': }
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)

      if os[:family].casecmp('RedHat') == 0
        shell 'sleep 10' # we need to wait a bit until the OSD is up

        shell 'ceph -s', { :acceptable_exit_codes => [0] } do |r|
          expect(r.stdout).to match(/1 mons at/)
          expect(r.stderr).to be_empty
        end

        shell 'ceph osd tree | grep osd.0', { :acceptable_exit_codes => [0] } do |r|
          expect(r.stdout).to match(/up/)
          expect(r.stderr).to be_empty
        end
      end
    end
  end

end
