Puppet::Type.newtype(:ceph_fs) do
  ensurable

  newparam(:name) do
    isnamevar
    desc 'Name of the file system'
    newvalues(/.+/)
  end

  newparam(:cluster) do
    isnamevar
    defaultto 'ceph'
    desc 'Name of the cluster'
    newvalues(/.+/)
  end

  newproperty(:metadata_pool_name) do
    desc 'Name of the metadata pool'
    newvalues(/.+/)
  end

  newproperty(:data_pool_name) do
    desc 'Name of the data pool'
    newvalues(/.+/)
  end

  autorequire(:ceph_pool) do
    [self[:metadata_pool_name], self[:data_pool_name]]
  end

  validate do
    if ! self[:metadata_pool_name]
      raise(Puppet::Error, 'metadata_pool_name is required')
    end
    if ! self[:data_pool_name]
      raise(Puppet::Error, 'data_pool_name is required')
    end
  end

  def self.title_patterns
    cluster = Regexp.new(/[^\/]+/)
    name = Regexp.new(/.+/)
    [
      [
        /^(#{cluster})\/(#{name})$/,
        [
          [:cluster],
          [:name]
        ]
      ],
      [
        /^(#{name})$/,
        [
          [:name]
        ]
      ]
    ]
  end
end
