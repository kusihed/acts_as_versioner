ActsAsVersioner
=================

This gem is versioning changes of a database table into a underlying table with the same name rules but a "_versions" appendix. Just add
"acts_as_versioner" in class definition of a model you want versioning to happen. Then create a new table by using the method "create_versioned_table". If you change tables, make sure the changes take also place in the versioned table, you can use the method "adapt_versioned_table" for that (User.adapt_versioned_table).

table name: "name of the original table in singluar demodulized form" + "_versions"
table format:
  - Primary Key: id integer not null auto_increment
  - "action": 
  	* 0 stands for created
	* 1 stands for updated
	* 2 stands for destroyed
  - From here there are the same columns like in the original table. It must be pointed out that the column "id" of the original table is in the format  of the original table in singluar demodulized form" + "_id"
  - Timestamps are automatically added
  - Editor id's are added through Userstamp

This gem expands a model class, marked with keyword "acts_as_versioner", with following methods:
	
	def get_current_version
		Returns the current version.

    def get_versions
		Returns all versions of a model.

Userstamp
=========

This gem expects a current_user to be present (devise, authlogic etc). In order to be able to access to current_user in models and modules, necessary method in application_controller and user.rb have to be available. If there is no current_user Userstamp will set 0 as version editor...

app/controllers/application_controller
---

around_action :setcurrentuser, :except => [:sign_in]
....

protected

def setcurrentuser
  User.current_user = current_user.nil? ? nil : User.find(current_user.id)
  yield
ensure
  User.current_user = nil
end

app/models/user.rb
---

def self.current_user
  Thread.current[:current_user]
end

def self.current_user=(usr)
  Thread.current[:current_user] = usr
end