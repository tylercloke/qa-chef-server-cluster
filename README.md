[![Stories in Ready](https://badge.waffle.io/chef/qa-chef-server-cluster.svg?label=ready&title=Ready)](http://waffle.io/chef/qa-chef-server-cluster)
[![Stories in Ready](https://badge.waffle.io/chef/qa-chef-server-cluster.svg?label=in%20progress&title=In%20Progress)](http://waffle.io/chef/qa-chef-server-cluster)
Quality Advocacy Chef Server Cluster
========
Recipes for installing, upgrading and testing Chef Server 12 topologies.  This cookbook is not designed as an idempotent
tool for managing chef servers. It is designed to accept package versions and run the install instructions
as documented for each configuration scenario from [Install Chef Server 12](https://docs.chef.io/install_server.html) and
[Upgrade Chef Server 12](https://docs.chef.io/upgrade_server.html).

# Requirements
* aws config

# Usage
1. Run `rake prep` to install dependencies
1. Run `chef-client -z -o qa-chef-server-cluster` for out of the box functionality
1. Review [User Guide](docs/user-guide.md)
 * [JSON Attributes](docs/user-guide.md#setting-json-attributes-via-chef-client)
 * [JSON Generator](docs/user-guide.md#generate-json-attributes)
 * [Automatic Chef Run](docs/user-guide.md#initiate-chef-run-with-generated-config)
 * [Configure Data Bags](docs/user-guide.md#data-bags)

# Test Kitchen
`kitchen list` to see available test suites

## End to End Cluster Validation
The following process applies to all topologies.

1. Create and install initial cluster
1. Upgrade existing cluster
1. Run pedant
1. Destroy cluster

### Main Cluster Recipes
Current supported topologies are `standalone-server`, `tier-cluster` and `ha-cluster`.

`<topology>`: Creates and install the initial cluster

`<topology>-upgrade`: Upgrades an existing cluster

`<topology>-test`: Executes cluster tests (currently runs pedant)

`<topology>-destroy`: Destroys the cluster

### Other Cluster Recipes
`<topology>-logs`: Runs `chef-server-ctl gather-logs`, and downloads the archives and any error logs (chef-stacktrace.out)
Note: the install and upgrade provision recipes download logs during execution.  This is intended to be used on-demand.

`<topology>-end-to-end`: Helper recipe for running the main cluster recipes in sequence.

`ha-cluster-trigger-failover`: Triggers an HA failover and verifies backend statuses. (Currently only fails over from initial bootstrap)

#### Execution
`chef-client -z -o qa-chef-server-cluster::<topology>-<recipe>`

## Configuration
### Setting JSON attributes via chef-client

```
Note: All packages are downloaded from artifactory using the `omnibus_artifactory_artifact` resource.
```
## Generate JSON Attributes
`bin/generate-config --help`

Execute `bin/generate-config` to see the default output in attributes.json.

The file can be edited, but it is recommended to use the cli options to generate new files.  If a config option is not available please sumbit an issue.

The bin script can automatically run chef-client with the generated attributes using the `r, --run-recipe` option.

Or run `chef-client -z -j <attributes>.json -o qa-chef-server-cluster<::optional recipe>`

## Data Bags
This project will use an insecure ssh key by default.  If your instances are public it is recommened to create a new ssh key data bag
and change the key name settings in .chef/knife.rb, chef-provisioner-key-name and bootstrap_options => key_name values.  This will be
configurable in a later version.

### Version Resolution
This cookbook wraps the `omnibus_artifactory_artifact` resource from the `omnibus_artifactory_artifact` cookbook to resolve and download packages from Artifactory repos.
Versions are mainly categorized by two parameters: which version and integration build support.  These params are derived based on the version input.

Using the bin script options, the versions can be derived using the following options, and the attributes file will be generated with the correct paramters for the resource.

`bin/generate-config --help` to see updated descriptions.

|Description|Value|
|-----------|-----|
|install latest build from omnibus-stable-local|`latest-stable`|
|install latest build from omnibus-current-local|`latest-current`|
|install latest integration build for a specfic version by appending `+` (default: omnibus-current-local)|`1.2.3+`|
|install specfic build (default: omnibus-stable-local)|`1.2.3`|
|install specific build by setting full version (default: omnibus-current-local)|`1.2.3+20150120085009`|
|download from any URL | any valid URL |

Each default repo can be overridden by setting the `-repo` options for the related package.

Review some common [config patterns](config-patterns.md)

# Credit
This wrapper cookbook deserves the recognition of Paul Mooring <paul@chef.io> and 
Joshua Timberman <joshua@chef.io> for their great work on the chef-server-cluster and chef-server-ingredient cookbooks.

# License and Author
Author: Patrick Wright patrick@chef.io.com

Copyright (C) 2014 Chef Software, Inc. legal@chef.io

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
