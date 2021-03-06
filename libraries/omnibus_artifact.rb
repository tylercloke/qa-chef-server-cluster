#
# Cookbook Name:: qa-chef-server-cluster
# LWRPs:: omnibus_artifact
#
# Author: Patrick Wright <patrick@chef.io>
# Copyright (C) 2015, Chef Software, Inc. <legal@chef.io>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Resource::OmnibusArtifact < Resource::LWRPBase
    self.resource_name = :omnibus_artifact

    actions :default
    default_action :default

    attribute :project,             name_attribute: true
    attribute :version
    attribute :integration_builds
    attribute :repo
  end

  class Provider::OmnibusArtifact < Provider::LWRPBase
    action(:default) do
      omnibus_artifactory_artifact new_resource.project do
        version format_version(new_resource.version)
        integration_builds new_resource.integration_builds
        repo new_resource.repo
      end

      package new_resource.project do
        source omnibus_artifactory_artifact_local_path(new_resource.project)
        provider value_for_platform_family(:debian => Chef::Provider::Package::Dpkg)
      end
    end

    def format_version(version)
      if version.start_with?('latest')
        version.gsub!('-', '_')
        return version.to_sym
      end
      version
    end
  end
end
