#! /bin/bash
# Installation of ceph cluster via puppet apply
# 2014-05-11 david@nine.ch - initial version

set -x
set -e

usage ()
{
echo "
Usage: ${0##*/} -i mon-ips -m mons --public subnet --cluster subnet [--osd osd [--journal journal]] [-h/--help]

-i mon-ips          -> list of mon ips

-m mons             -> mon names

--public subnet     -> the public subnet

--cluster subnet    -> the cluster subnet

-h/--help           -> this help

Example: ${0##*/} -i '192.168.11.10, 192.168.11.11' -m 'ceph0, ceph1' --public 192.168.11.0/24 --cluster 172.16.33.0/24 --osd /dev/vdb4 --journal /dev/vdb3
"
}
 
PARAM=`getopt -o i:m:h --long public:,cluster:,osd:,journal:,help -- "$@"`
 
if [ "$?" != "0" ] ; then usage ; exit 1 ; fi
 
eval set -- "$PARAM"
while true ; do
    case "$1" in
        -i) ips="$2" ; shift 2 ;;
        -m) mons="$2" ; shift 2 ;;
        --public) pub_subnet="$2" ; shift 2 ;;
        --cluster) cluster_subnet="$2" ; shift 2 ;;
        --osd) osd="$2" ; shift 2 ;;
        --journal) journal="$2" ; shift 2 ;;
        -h|--help) usage ; exit 0 ; shift ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

missing_param()
{
if [[ -z "$2" ]]; then
    echo "you didn't provide necessary parameter $1"
    echo
    usage
    exit 1
fi
}

missing_param mon-ips $ips
missing_param mons $mons
missing_param public $pub_subnet
missing_param cluster $cluster_subnet

# puppet would do it, but we need it to generate the keys:
apt-get install -y ceph

# install dependencies
apt-get install -y git

# install puppet >=3.x
wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
apt-get update
apt-get install -y puppet

# clean firewall
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# configure minimal hiera
cat > /etc/puppet/hiera.yaml << EOF
---                                                                                                                                                                                                                :backends:                                                                                                                                                                                                         
  - yaml                                                                                                                                                                                                           
:yaml:                                                                                                                                                                                                             
  :datadir: /var/lib/hiera                                                                                                                                                                                         
:hierarchy:                                                                                                                                                                                                        
  - "nodes/%{::hostname}"
  - common
EOF

# get and configure openstack puppet module
git clone  https://github.com/ninech/puppet-ceph.git /etc/puppet/modules/ceph
# and install dependencies using librarian-puppet
apt-get install -y rubygems
gem install librarian-puppet
cp /etc/puppet/modules/ceph/Puppetfile /etc/puppet/
cd /etc/puppet && librarian-puppet install

# customize common.yaml
mkdir -p /var/lib/hiera/nodes
cat > /var/lib/hiera/common.yaml << EOF
---
######## Ceph.conf global
ceph::conf::fsid: '4b5c8c0a-ff60-454b-a1b4-9747aa737d19'
ceph::conf::authentication_type: 'cephx'
ceph::conf::public_network: '${pub_subnet}'
ceph::conf::cluster_network: '${cluster_subnet}'

######## Ceph.conf global mon
ceph::conf::mon_initial_members: '${mons}'
ceph::conf::mon_host: '${ips}'

######## Ceph.conf global osd
ceph::conf::osd_pool_default_pg_num: '200'
ceph::conf::osd_pool_default_pgp_num: '200'
ceph::conf::osd_pool_default_size: '2'
ceph::conf::osd_pool_default_min_size: '1'

######## Keys
# you might consider changing these:
ceph::key::admin: 'AQBMGHJTkC8HKhAAJ7NH255wYypgm1oVuV41MA=='
ceph::key::mon: 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg=='
ceph::key::bootstrap_osd: 'AQARG3JTsDDEHhAAVinHPiqvJkUi5Mww/URupw=='
EOF

if [[ -n ${osd} ]]; then
if [[ -n ${journal} ]]; then
cat > /var/lib/hiera/nodes/$(hostname).yaml << EOF
---
######## OSD
ceph::osd::osds: {'${osd}': {journal: '${journal}'}}
EOF

else
cat > /var/lib/hiera/nodes/$(hostname).yaml << EOF
---
######## OSD
ceph::osd::osds: {'${osd}': }
EOF

fi
fi

set +x
set +e

# apply the relevant puppet modules
puppet apply --report /etc/puppet/modules/havana/tests/mon.pp
puppet apply --report /etc/puppet/modules/havana/tests/osd.pp

