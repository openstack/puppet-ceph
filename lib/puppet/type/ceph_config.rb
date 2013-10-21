#   Copyright (C) Dan Bode <bodepd@gmail.com>
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
# Author: Dan Bode <bodepd@gmail.com>
# Author: Mathieu Gagne <mgagne>


Puppet::Type.newtype(:ceph_config) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from ./ceph.conf'
    newvalues(/\S+\/\S+/)
  end

  # required in order to be able to unit test file contents
  # Note: purge will not work on over-ridden file_path
  # lifted from ini_file
  newparam(:path) do
    desc 'A file path to over ride the default file path if necessary'
    validate do |value|
      unless (Puppet.features.posix? and value =~ /^\//) or (Puppet.features.microsoft_windows? and (value =~ /^.:\// or value =~ /^\/\/[^\/]+\/[^\/]+/))
        raise(Puppet::Error, "File paths must be fully qualified, not '#{value}'")
      end
    end
    defaultto false
  end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |value|
      value = value.to_s.strip
      value.capitalize! if value =~ /^(true|false)$/i
      value
    end
  end
end
