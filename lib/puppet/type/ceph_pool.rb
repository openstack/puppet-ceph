Puppet::Type.newtype(:ceph_pool) do
  ensurable

  newparam(:name) do
    isnamevar
    desc 'Name of the pool'
    newvalues(/.+/)
  end

  newparam(:cluster) do
    isnamevar
    desc 'Name of the cluster'
    newvalues(/.+/)
  end

  newproperty(:pg_num) do
    desc 'Number of PGs'
    defaultto 64
    validate do |v|
      if v.is_a?(Integer)
        if v <= 0
          raise ArgumentError, "Invalid pg_num #{value}. Requires a positive value, not #{value.class}"
        end
      else
        raise ArgumentError, "Invalid pg_num #{value}. Requires an Integer, not a #{value.class}"
      end
      return true
    end
  end

  newproperty(:pgp_num) do
    desc 'Number of PGs for placement'
    validate do |v|
      if v.is_a?(Integer)
        if v <= 0
          raise ArgumentError, "Invalid pgp_num #{value}. Requires a positive value, not #{value.class}"
        end
      else
        raise ArgumentError, "Invalid pgp_num #{value}. Requires an Integer, not a #{value.class}"
      end
      return true
    end
  end

  newproperty(:size) do
    desc 'Pool size'
    validate do |v|
      if v.is_a?(Integer)
        if v <= 0
          raise ArgumentError, "Invalid size #{value}. Requires a positive value, not #{value.class}"
        end
      else
        raise ArgumentError, "Invalid size #{value}. Requires an Integer, not a #{value.class}"
      end
      return true
    end
  end

  newproperty(:application) do
    desc 'Associated application'
    newvalues(/.+/)
  end

  validate do
    if self[:pgp_num]
      if self[:pgp_num] > self[:pg_num]
        raise(Puppet::Error, 'pgp_num should not exceed pg_num')
      end
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
