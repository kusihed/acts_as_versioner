class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end  

class Entry < ApplicationRecord
  acts_as_versioner
end

class User < ApplicationRecord
  def self.current_user
	  Thread.current[:current_user]
  end	

  def self.current_user=(usr)
	  Thread.current[:current_user] = usr
  end
end  

