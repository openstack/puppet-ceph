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
# Author: Andrew Woodward <xarses>

Puppet::Type.type(:ceph_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def section
    resource[:name].split('/', 2).first
  end

  def setting
    resource[:name].split('/', 2).last
  end

  def separator
    ' = '
  end

  def self.file_path
    '/etc/ceph/ceph.conf'
  end

  # required to be able to hack the path in unit tests
  # also required if a user wants to otherwise overwrite the default file_path
  # Note: purge will not work on over-ridden file_path
  def file_path
    if not resource[:path]
      self.class.file_path
    else
      resource[:path]
    end
  end

end
