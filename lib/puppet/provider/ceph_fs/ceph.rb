require 'puppet'
require 'puppet/provider/ceph'

Puppet::Type.type(:ceph_fs).provide(
  :ceph,
  :parent => Puppet::Provider::Ceph
) do
  desc 'Provider for ceph filesystem'

  def create
    ceph_cmd(@resource[:cluster], ['fs', 'new', @resource[:name], @resource[:metadata_pool_name], @resource[:data_pool_name]])
  end

  def destroy
    ceph_cmd(@resource[:cluster], ['fs', 'rm', @resource[:name], '--yes-i-really-really-mean-it'])
  end

  def exists?
    fs = find_fs
    if fs.nil?
      return false
    end
    return true
  end

  def metadata_pool_name
    fs = find_fs
    fs['metadata_pool']
  end

  def data_pool_name
    fs = find_fs
    # TODO(tkajinam): data pool is a list. Should we support multiple values ?
    fs['data_pools'][0]
  end

  [
    :metadata_pool_name,
    :data_pool_name,
  ].each do |attr|
    define_method(attr.to_s + "=") do |value|
      fail("Property #{attr.to_s} does not support being updated")
    end
  end

  private

  def find_fs
    fs_list = parse_json(
      ceph_cmd(@resource[:cluster], ['fs', 'ls', '-f', 'json']))
    fs_list.each do |fs|
      if fs['name'] == @resource[:name]
        return fs
      end
    end
    return nil
  end
end
