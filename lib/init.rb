require File.dirname(__FILE__) + 'acts_as_versioner.rb'
ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::Versioner
end

module ActiveRecord::Acts::Versioner
  @@configurator = {
    :default_versioned_class_name => '_versions',
    :default_versiond_created_at => 'created_at',
    :default_versiond_updated_at => 'updated_at',
    :default_versiond_created_by => 'created_by',
    :default_versiond_updated_by => 'updated_by'
  }
end  

require File.dirname(__FILE__) + 'userstamp.rb'
class ActiveRecord::Base
  include Userstamp
end