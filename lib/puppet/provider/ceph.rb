require 'puppet'

class Puppet::Provider::Ceph < Puppet::Provider

  initvars
  commands :ceph => 'ceph'

  protected

  # NOTE(tkajinam): JSON outputs from ceph command includes garbage empty lines
  def parse_json(value)
    JSON.parse(value.gsub(/^$\n/, '').strip)
  end

  def ceph_cmd(cluster, args)
    ceph('--cluster', cluster, *args)
  end
end
