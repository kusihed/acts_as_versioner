require File.dirname(__FILE__) + '/acts_as_versioner/acts_as_versioner.rb'
require File.dirname(__FILE__) + '/acts_as_versioner/userstamp.rb'
module ActiveRecord::Acts::Versioner
  @@configurator = {
    :default_versioned_class_name => '_versions',
    :default_versiond_created_at => 'created_at',
    :default_versiond_updated_at => 'updated_at',
    :default_versiond_created_by => 'created_by',
    :default_versiond_updated_by => 'updated_by'
  }
  mattr_reader :configurator
end

class ActiveRecord::Base
  include ActiveRecord::Acts::Versioner
  include Userstamp
end
