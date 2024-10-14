require 'puppet'
require 'puppet/provider/ceph'

Puppet::Type.type(:ceph_pool).provide(
  :ceph,
  :parent => Puppet::Provider::Ceph
) do
  desc 'Provider for ceph pools'

  def create
    args = []
    args << @resource[:pg_num]
    if @resource[:pgp_num]
      args << @resource[:pgp_num]
    end
    ceph_cmd(@resource[:cluster], ['osd', 'pool', 'create', @resource[:name], *args])

    if @resource[:size]
      set_pool_property('size', @resource[:size])
    end
    if @resource[:application]
      ceph_cmd(@resource[:cluster], ['osd', 'pool', 'application','enable', @resource[:name], @resource[:application]])
    end
  end

  def destroy
    ceph_cmd(@resource[:cluster], ['osd', 'pool', 'delete', @resource[:name], @resource[:name], '--yes-i-really-really-mean-it'])
  end

  def exists?
    pools = parse_json(ceph_cmd(@resource[:cluster], ['osd', 'pool', 'ls', '-f', 'json']))
    pools.include?(@resource[:name])
  end

  def size
    get_pool_property('size')
  end

  def size=(value)
    set_pool_property('size', value)
  end

  def pg_num
    get_pool_property('pg_num')
  end

  def pg_num=(value)
    set_pool_property('pg_num', value)
  end

  def pgp_num
    get_pool_property('pgp_num')
  end

  def pgp_num=(value)
    set_pool_property('pgp_num', value)
  end

  def application
    val = parse_json(ceph_cmd(@resource[:cluster], ['osd', 'pool', 'application', 'get', @resource[:name], '-f', 'json']))
    val.keys[0]
  end

  def application=(value)
    if application.nil?
      ceph_cmd(@resource[:cluster], ['osd', 'pool', 'application', 'enable', @resource[:name], value])
    else
      raise Puppet::Error, "The pool #{@resource[:name]} already has application set"
    end
  end

  private

  def get_pool_property(key)
    parse_json(ceph_cmd(@resource[:cluster], ['osd', 'pool', 'get', @resource[:name], key, '-f', 'json']))[key]
  end

  def set_pool_property(key, value)
    ceph_cmd(@resource[:cluster], ['osd', 'pool', 'set', @resource[:name], key, value])
  end
end
