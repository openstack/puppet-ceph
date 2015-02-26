ceph
====

#### Table of Contents

1. [Overview - What is the ceph module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with ceph](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
7. [Integration - Apply the module and test restults](#integration-tests)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The ceph module is intended to leverage all [Ceph](http://ceph.com/) has to offer and allow for a wide range of use case. Although hosted on the OpenStack infrastructure, it does not require to sign a CLA nor is it restricted to OpenStack users. It benefits from a structured development process that helps federate the development effort. Each feature is tested with integration tests involving virtual machines to show that it performs as expected when used with a realistic scenario.

Module Description
------------------

The ceph module deploys a [Ceph](http://ceph.com/) cluster ( MON, OSD ), the [Cephfs](http://ceph.com/docs/next/cephfs/) file system and the [RadosGW](http://ceph.com/docs/next/radosgw/) object store. It provides integration with various environments ( OpenStack ... ) and components to be used by third party puppet modules that depend on a Ceph cluster.

Setup
-----

Implementation
--------------

A [blueprint](https://wiki.openstack.org/wiki/Puppet-openstack/ceph-blueprint) contains an inventory of what is desirable. It was decided to start from scratch and implement one module at a time.

Limitations
-----------

Use Cases
---------

* [I want to try this module, heard of ceph, want to see it in action](USECASES.md#i-want-to-try-this-module,-heard-of-ceph,-want-to-see-it-in-action)
* [I want to operate a production cluster](USECASES.md#i-want-to-operate-a-production-cluster)
* [I want to run benchmarks on three new machines](USECASES.md#i-want-to-run-benchmarks-on-three-new-machines)

Development
-----------

```
git clone https://github.com/stackforge/puppet-ceph.git
cd puppet-ceph
sudo gem install bundler
bundle install
```

The developer documentation of the puppet-openstack project is the reference:

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Mailing lists:

* (puppet-openstack)[https://groups.google.com/a/puppetlabs.com/forum/#!forum/puppet-openstack]
* (ceph-devel)[http://ceph.com/resources/mailing-list-irc/]

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
BUNDLE_PATH=/tmp/vendor bundle install
BUNDLE_PATH=/tmp/vendor bundle exec rspec spec/acceptance
```

The BEAKER_set environment variable contains the resource set of linux
distribution configurations for which integration tests are going
to be run. Available values are

* two-ubuntu-server-1204-x64
* ubuntu-server-1204-x64
* two-centos-64-x64
* centos-64-x64

The default is

```
BUNDLE_PATH=/tmp/vendor \
BEAKER_set=two-ubuntu-server-1204-x64 \
bundle exec rspec spec/acceptance
```

Deprecated Integration Tests
----------------------------

Relies on
[rspec-system-puppet](https://github.com/puppetlabs/rspec-system-puppet)
and tests are in spec/system. It runs virtual machines and requires
4GB of free memory and 10GB of free disk space.

* [Install Vagrant and Virtualbox](http://docs-v1.vagrantup.com/v1/docs/getting-started/)
* sudo apt-get install ruby-dev libxml2-dev libxslt-dev # nokogiri dependencies
* mv Gemfile-rspec-system Gemfile # because of https://bugs.launchpad.net/openstack-ci/+bug/1290710
* BUNDLE_PATH=/tmp/vendor bundle install
* BUNDLE_PATH=/tmp/vendor bundle exec rake lint
* BUNDLE_PATH=/tmp/vendor bundle exec rake spec
* git clone https://github.com/bodepd/scenario_node_terminus.git ../scenario_node_terminus
* BUNDLE_PATH=/tmp/vendor bundle exec rake spec:system
* BUNDLE_PATH=/tmp/vendor RS_SET=two-ubuntu-server-1204-x64 bundle exec rake spec:system
* BUNDLE_PATH=/tmp/vendor RS_SET=two-centos-66-x64 bundle exec rake spec:system

The RELEASES environment variable contains the list of ceph releases
for which integration tests are going to be run. The default is

```
BUNDLE_PATH=/tmp/vendor \
RELEASES='dumpling firefly giant' \
bundle exec rake spec:system
```

The RS_SET environment variable contains the resource set of linux
distribution configurations for which integration tests are going
to be run. Available values are

* two-ubuntu-server-1204-x64
* ubuntu-server-1204-x64
* two-centos-66-x64
* centos-66-x64

The default is

```
BUNDLE_PATH=/tmp/vendor \
RS_SET=two-ubuntu-server-1204-x64 \
bundle exec rake spec:system
```

The MACHINES environment variable contains the list of virtual
machines that are used for integration tests. This needs to match
with the RS_SET above. I.e. for a two-* RS_SET use 2 machines.
The default is

```
MACHINES='first second' \
bundle exec rake spec:system
```

On success it should complete with

```
...
=end=============================================================
Finished in 4 minutes 1.7 seconds
1 example, 0 failures
```

Example invocation of gerritexec:

```
script='bash -c "'
script+='mv Gemfile-rspec-system Gemfile ; bundle install ; '
script+='RS_SET=two-ubuntu-server-1204-x64 bundle exec rake spec:system ; '
script+='RS_SET=two-centos-66-x64 bundle exec rake spec:system ; '
script+='" > /tmp/out 2>&1 ; r=$? ; '
script+='echo https://pypi.python.org/pypi/gerritexec output: ; '
script+='pastebinit /tmp/out ; '
script+='exit $r #'
GEM_HOME=~/.gems gerritexec \
   --hostname review.openstack.org \
   --verbose --username puppetceph \
   --script "$script" \
   --project stackforge/puppet-ceph
```

Contributors
------------

* https://github.com/stackforge/puppet-ceph/graphs/contributors

Release Notes
-------------
