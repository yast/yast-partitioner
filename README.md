# YaST - The Partitioner Module #

[![Travis Build](https://travis-ci.org/yast/yast-partitioner.svg?branch=master)](https://travis-ci.org/yast/yast-partitioner)
[![Jenkins Build](http://img.shields.io/jenkins/s/https/ci.opensuse.org/yast-partitioner-master.svg)](https://ci.opensuse.org/view/Yast/job/yast-partitioner-master/)
[![Coverage Status](https://img.shields.io/coveralls/yast/yast-partitioner.svg)](https://coveralls.io/r/yast/yast-partitioner?branch=master)
[![Code Climate](https://codeclimate.com/github/yast/yast-partitioner/badges/gpa.svg)](https://codeclimate.com/github/yast/yast-partitioner)

## Testing

Package can be installed from [storage-ng OBS repo](https://build.opensuse.org/project/show/YaST:storage-ng) as yast2-partitioner.
To run it on running system call it via `yast2 partitioner` or `yast2 storage`.

It is also possible to run it with device graph from file with `yast2 partitioner_testing <path to file>`. Supported formats are
[yast2-storage-ng yml format](https://github.com/yast/yast-storage-ng/blob/master/doc/fake-devicegraphs-yaml-format.md)
and [libstorage xml format](https://github.com/openSUSE/libstorage-ng).

[//]: # (TODO: find better link for xml format)

## Intentional Differences to Old Expert Partitioner

- does not display info about cylinders and sectors
