require File.dirname(__FILE__) + '/acts_as_versioner/acts_as_versioner.rb'
require File.dirname(__FILE__) + '/acts_as_versioner/userstamp.rb'
module ActiveRecord::Acts::Versioner
  @@configurator = {
    :default_versioned_class_name => 'Version',
    :default_versioned_table_name => '_versions',
    :default_versioned_created_at => 'created_at',
    :default_versioned_updated_at => 'updated_at',
    :default_versioned_created_by => 'created_by',
    :default_versioned_updated_by => 'updated_by'
  }
  mattr_reader :configurator
end

class ActiveRecord::Base
  include Userstamp
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::Versioner
end
