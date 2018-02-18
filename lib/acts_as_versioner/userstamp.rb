module Userstamp
  extend ActiveSupport::Concern

  included do
    # It's important to use before_save here because of the hierarchy in callbacks (see acts_as_versioner)
    before_save :set_stamps
  end
  
  def set_stamps
    if defined?(User)
      stamper = 0 # System
      stamper = User.current_user.id if User.current_user
      if self.id.blank?
        self[ActiveRecord::Acts::Versioner::configurator[:default_versioned_created_by]] = stamper if self.has_attribute? ActiveRecord::Acts::Versioner::configurator[:default_versioned_created_by]
        self[ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_by]] = stamper if self.has_attribute? ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_by]
      else
        self[ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_by]] = stamper if self.has_attribute? ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_by]
      end
    end
  end
  
end
