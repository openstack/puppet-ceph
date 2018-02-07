ceph
====

#### Table of Contents

1. [Overview - What is the ceph module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with ceph](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Use Cases - Examples of how to use this module](#limitations)
7. [Development - Guide for contributing to the module](#development)
8. [Beaker Integration Tests - Apply the module and test results](#beaker-integration-tests)
9. [Contributors - Those with commits](#contributors)
10. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The ceph module is intended to leverage all [Ceph](http://ceph.com/) has to offer and allow for a wide range of use case. This module was originally forked from the openstack/puppet-ceph module and since changed to support uses cases required by our project.  Additional functionality was also added to support more Ceph services.  It has diverged sufficiently that a clean merge from the origin repository is likely to be difficiult.  At some point an evaluation of this module compared to the current state of the openstack origin may be in order to identify commits worth merging or pull-requests that could be fed back.  

Some links to documentation are left as-is from the original as they may still be relevant.  Parts relevant to using the module are updated with current usage.  

Summary of added features or changes:

- Supports multiple cluster configs on same host changing ceph::cluster class to resource.  
- Change ceph::rgw class to resource allowing management of multiple instances on same host
- Modify other classes as needed to specify cluster name
- Added additional params to ceph_cluster such as osd_crush_location, debugging control, etc (see manifest)
- Turn ceph::mds class into resource, add service/directory management.
- Add REST API resource ceph::restapi
- Add ceph-mgr resource ceph::mgr
- Modify ceph::osd to support bluestore and create logical volumes for data and block.db devices
- Removed filestore support

Module Description
------------------

The ceph module deploys a [Ceph](http://ceph.com/) cluster ( MON, OSD , MGR), the [Cephfs](http://ceph.com/docs/master/cephfs/) file system and the [RadosGW](http://ceph.com/docs/master/radosgw/) object store. It provides integration with various environments and components to be used by third party puppet modules that depend on a Ceph cluster.

Setup
-----

Implementation
--------------

A [blueprint](https://wiki.openstack.org/wiki/Puppet-openstack/ceph-blueprint) contains an inventory of what is desirable. It was decided to start from scratch and implement one module at a time.

Limitations
-----------

We follow the OS compatibility of Ceph. With the release of infernalis this is currently:

* CentOS 7 or later
* Debian Jessie 8.x or later
* Ubuntu Trusty 14.04 or later
* Fedora 22 or later

Use Cases
---------

* [I want to try this module, heard of ceph, want to see it in action](USECASES.md#i-want-to-try-this-module,-heard-of-ceph,-want-to-see-it-in-action)
* [I want to operate a production cluster](USECASES.md#i-want-to-operate-a-production-cluster)
* [I want to run benchmarks on three new machines](USECASES.md#i-want-to-run-benchmarks-on-three-new-machines)

Development
-----------

```
git clone https://github.com/MI-OSiRIS/puppet-ceph
cd puppet-ceph
sudo gem install bundler
bundle install
```

The developer documentation of the puppet-openstack project is the reference:

* https://wiki.openstack.org/wiki/Puppet#Developer_documentation

Mailing lists:

* [puppet-openstack](https://groups.google.com/a/puppetlabs.com/forum/#!forum/puppet-openstack)
* [ceph-devel](http://ceph.com/resources/mailing-list-irc/)

IRC channels:

* irc.freenode.net#puppet-openstack
* irc.oftc.net#ceph-devel

Beaker Integration Tests
------------------------

Relies on
[rspec-beaker](https://github.com/puppetlabs/beaker-rspec)
and tests are in spec/acceptance.
It also requires [Vagrant and Virtualbox](http://docs-v1.vagrantup.com/v1/docs/getting-started/)
.

```
bundle install
bundle exec rspec spec/acceptance
```

The BEAKER_set environment variable contains the resource set of linux
distribution configurations for which integration tests are going
to be run. Available values are

* two-centos-70-x64
* centos-70-x64
* two-ubuntu-server-1404-x64
* ubuntu-server-1404-x64

The default is

```
BEAKER_set=two-ubuntu-server-1404-x64 \
bundle exec rspec spec/acceptance
```

Contributors
------------

* https://github.com/openstack/puppet-ceph/graphs/contributors
* https://github.com/MI-OSiRIS/puppet-ceph/graphs/contributors

Release Notes
-------------
