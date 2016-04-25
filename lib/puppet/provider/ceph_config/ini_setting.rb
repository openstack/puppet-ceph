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
    resource[:name].split('/', 3)[1]
  end

  def setting
    resource[:name].split('/', 3)[2]
  end

  def separator
    ' = '
  end

  # I don't understand how to make this properly set using the value of the :name resource
  # it seems impossible to reference the resource[] variable in any class definition
  # and I'm not sure if there is some other global var that I can reference to find it
  # so I guess I don't understand puppet and/or ruby here (bmeekhof@umich.edu)

  # ultimately the net effect is we can't (automatically) purge any files besides the default here
  def self.file_path
        '/etc/ceph/ceph.conf'
  end

  # required to be able to hack the path in unit tests
  # also required if a user wants to otherwise overwrite the default file_path
  # Note: purge will not work on over-ridden file_path
  def file_path
    if not resource[:path]
      '/etc/ceph/' + resource[:name].split('/', 3)[0] + '.conf'
    else
      resource[:path]
    end
  end

end
