name             'qa-chef-server-cluster'
maintainer       'Patrick Wright'
maintainer_email 'patrick@chef.io'
license          'all_rights'
description      'Installs/Configures QA clusters'
version          '1.0.0'

depends 'chef-server-cluster'
depends 'omnibus-artifactory-artifact'
depends 'lvm'
depends 'apt'
depends 'build-essential'
