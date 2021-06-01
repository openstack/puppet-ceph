Team and repository tags
========================

[![Team and repository tags](https://governance.openstack.org/tc/badges/puppet-ceph.svg)](https://governance.openstack.org/tc/reference/tags/index.html)

<!-- Change things from this point on -->

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
8. [Contributors - Those with commits](#contributors)
9. [Release Notes - Notes on the most recent updates to the module](#release-notes)
10. [Repository - Repository for the module](#repository)

Overview
--------

The ceph module is intended to leverage all [Ceph](http://ceph.com/) has to offer and allow for a wide range of use case. Although hosted on the OpenStack infrastructure, it does not require to sign a CLA nor is it restricted to OpenStack users. It benefits from a structured development process that helps federate the development effort. Each feature is tested with integration tests involving virtual machines to show that it performs as expected when used with a realistic scenario.

Module Description
------------------

The ceph module deploys a [Ceph](http://ceph.com/) cluster ( MON, OSD ), the [Cephfs](http://docs.ceph.com/docs/master/cephfs/) file system and the [RadosGW](http://docs.ceph.com/docs/firefly/radosgw/) object store. It provides integration with various environments ( OpenStack ... ) and components to be used by third party puppet modules that depend on a Ceph cluster.

Setup
-----

Implementation
--------------

A [blueprint](https://wiki.openstack.org/wiki/Puppet/ceph-blueprint) contains an inventory of what is desirable. It was decided to start from scratch and implement one module at a time.

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
git clone https://github.com/openstack/puppet-ceph.git
cd puppet-ceph
sudo gem install bundler
bundle install
```

The developer documentation of the puppet-openstack project is the reference:

* https://docs.openstack.org/puppet-openstack-guide/latest/

Mailing lists:

* [puppet-openstack](https://groups.google.com/a/puppetlabs.com/forum/#!forum/puppet-openstack)
* [ceph-devel](http://ceph.com/resources/mailing-list-irc/)

IRC channels:

* irc.oftc.net#puppet-openstack
* irc.oftc.net#ceph-devel

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://docs.openstack.org/puppet-openstack-guide/latest/

Contributors
------------

* https://github.com/openstack/puppet-ceph/graphs/contributors

Release Notes
-------------

* https://docs.openstack.org/releasenotes/puppet-ceph

Repository
-------------

* https://opendev.org/openstack/puppet-ceph

