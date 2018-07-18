# This module serves to versioning of data sets. If a new data set is created, updated or destroyed, the old data set gets saved into a second table.
# The second table has the same name like the original table but is expanded with "Version".
# => E.g. User -> UserVersions

# ActsAsVersioner

module ActiveRecord
  module Acts
    module Versioner

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_versioner(options = {}, &extension)
          include ActiveRecord::Acts::Versioner::InstanceMethods

          # don't allow multiple calls
          return if self.included_modules.include?(ActiveRecord::Acts::Versioner::ActMethods)

          send :include, ActiveRecord::Acts::Versioner::ActMethods

          cattr_accessor :versioned_class_name, :versioned_foreign_key, :versioned_table_name

          send :attr_accessor

          self.versioned_class_name         = options[:class_name]  || "#{base_class}Version"
          self.versioned_table_name         = options[:table_name]  || "#{table_name_prefix}#{base_class.name.demodulize.underscore}#{ActiveRecord::Acts::Versioner::configurator[:default_versioned_class_name]}#{table_name_suffix}"
          self.versioned_foreign_key        = options[:versioned_foreign_key]  || "#{table_name_prefix}#{base_class.name.demodulize.underscore}_id"   # quick 'n' dirty fix

          if block_given?
            extension_module_name = "#{versioned_class_name}Extension"
            silence_warnings do
              self.const_set(extension_module_name, Module.new(&extension))
            end
            options[:extend] = self.const_get(extension_module_name)
          end

          class_eval do
            include options[:extend] if options[:extend].is_a?(Module)

            before_save :b_s
            before_destroy :b_d
            after_save :a_s
            after_destroy :a_d
          end

          # create the dynamic versioned model
          const_set(versioned_class_name, Class.new(ApplicationRecord)).class_eval do
            def self.reloadable? ; false ; end
          end

          versioned_class.table_name = "#{versioned_table_name}"
          versioned_class.belongs_to self.to_s.demodulize.underscore.to_sym, :class_name  => "#{self.to_s}::#{versioned_class_name}",  :foreign_key => versioned_foreign_key
          versioned_class.send :include, options[:extend] if options[:extend].is_a?(Module)
        end
      end

	  module InstanceMethods
	    attr_accessor :acts_as_versioner_model
	    attr_accessor :acts_as_versioner_mode

        # Returns the current version.
	    def get_current_version
          instance_eval(self.versioned_class_name).where([self.versioned_foreign_key + ' = ?', self.id]).order("#{ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_at]} desc, id desc").first
	    end

        # Returns all versions of a model.
	    def get_versions
          instance_eval(self.versioned_class_name).where([self.versioned_foreign_key + ' = ?', self.id]).order("#{ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_at]} asc, id asc").all
	    end

        # This methods returns all versions of associated tables (table that belong to the existing model).
	    def get_versions_children
	      associations = Hash.new # result hash
	      stack = Array.new # Stack of the same algorithm.

          # Initiate algorithm with the used model
	      versions = instance_eval(self.versioned_class_name).where([self.versioned_foreign_key + ' = ?', self.id]).order("#{ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_at]} asc, #{ActiveRecord::Acts::Versioner::configurator[:default_versioned_created_at]} asc").all
	      associations[self.versioned_class_name] = versions # Caching itself in the result hash
	      stack.push self.class => versions # Setting itself onto the stack

          # Main loop of the algorith
	      while class_struct = stack.pop
	        class_name = nil
	        data_set = nil

	        class_struct.each do |key_class_name, value_data_set|
	          class_name = key_class_name
	          data_set = value_data_set
	        end

            # Read all assocations
	        reflection_assoc = Array.new
	        reflection_assoc.concat(class_name.reflect_on_all_associations(:has_one))
	        reflection_assoc.concat(class_name.reflect_on_all_associations(:has_many))
	        reflection_assoc.compact!

            # Iterate through all associations
	        reflection_assoc.each do |association|
	          association_klass = association.klass
              # Is there a versioning table? If yes, go back to the beginning of the iteration..
              if association_klass.to_s.include?("version") then next end
	          child_associations_has_one = association_klass.reflect_on_all_associations(:has_one)
	          child_associations_has_many = association_klass.reflect_on_all_associations(:has_many)

              # Does the associated table have further associated tables and did they already be iterated through?
	          if (child_associations_has_one.empty? || child_associations_has_many.empty?) && associations[association_klass.versioned_class_name] != nil then next end

	          new_data_set = Array.new
              # Check if the table has been visited already. If yes, complete the data sets -> Does only happen if we have a table without associations.
	          if associations[association_klass.versioned_class_name] != nil then new_data_set = associations[association_klass.versioned_class_name] end

              foreign_ids = []
              data_set.each { |data|
                foreign_ids << instance_eval("data." + class_name.to_s.tableize.singularize.downcase + "_id.to_s")
              }

              unless foreign_ids.blank?
	            tmp_new_data_set = association_klass.versioned_class.where(["#{class_name.to_s.tableize.singularize.downcase}_id IN (?)", foreign_ids]).order("#{ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_at]} asc, #{ActiveRecord::Acts::Versioner::configurator[:default_versioned_created_at]} asc").all
	            unless tmp_new_data_set.blank? then new_data_set.concat(tmp_new_data_set) end
              end

              # Cache the found data sets into the result hash
	          associations[association_klass.versioned_class_name] = new_data_set
              # Additionally found data sets get saved on the stack for the next iteration
	          stack.push association_klass => new_data_set
	        end
	      end

          # Remove all double entries
          associations.each do |class_name_to_s, versionArray|
	        versionArray.uniq!
	      end

	      return associations
	    end

        private

        # This method overrides the default method "before_save" of the ActiveRecord class.
        # It is invoked before the actual saving takes place and serves to preparing the versioning.
	    def b_s
	      prepare_versioning
	    end

        # This method overrides the default method "before_destroy" of the ActiveRecord class.
        # It is invoked before the actual destroying takes place and serves to preparing the versioning.
	    def b_d
	      prepare_versioning 2
	    end

        # This method overrides the default method "after_save" of the ActiveRecord class.
        # It is invoked after the actual saving has token place and serves to execute the versioning.
	    def a_s
	      do_versioning
	    end

        # This method overrides the default method "after_destroy" of the ActiveRecord class.
        # It is invoked after the actual destroying has token place and serves to execute the versioning.
	    def a_d
	      do_versioning
	    end

        # This method is preparing the versioning. It copies the current object and saves it into a variable.
        # For the number it is assumed to be between 0 and 2 depending on the mode (0 = insert, 1 = update, 2 = delete).
	    def prepare_versioning(mode = 0)
	      @acts_as_versioner_mode = mode # mode : 0 = insert, 1 = update, 2 = delete
	      @acts_as_versioner_model = self.dup
          @acts_as_versioner_model.updated_at = Time.now

	      if mode == 0 && self.id != nil then @acts_as_versioner_mode = 1 end  
	    end

        # In this method the versioning is happening. It expects a copy of the current object in the variable @acts_as_versioner_mode.
        # It will be invoked after the method "prepare_versioning"
	    def do_versioning
	      attributes = Hash.new
          # Save variables and the values in a hash
	      @acts_as_versioner_model.attributes.each do |attribute, value|
	        attributes[attribute] = value unless attribute == "id" # ID has to be excluded because MassAssignment warning...
	      end

	      @acts_as_versioner_model = nil

	      attributes[self.versioned_foreign_key] = self.id
	      attributes[:action] = @acts_as_versioner_mode

	      modelversion = instance_eval(self.versioned_class_name).new(attributes)
	      modelversion.save(:validate => false)
	    end
	  end

      module ActMethods
        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end

        private

        def empty_callback() end #:nodoc:

        module ClassMethods

          # Returns an array of columns that are versioned.  See non_versioned_columns
          def versioned_columns
            self.columns.select { |c| c.name }
          end

          # Returns an instance of the dynamic versioned model
          def versioned_class
            const_get versioned_class_name
          end

          # Rake migration task to create the versioned table
          def create_versioned_table(create_table_options = {})
            versioned_table_name = self.to_s.underscore + ActiveRecord::Acts::Versioner::configurator[:default_versioned_class_name]
            puts table_name
            # create version column in main table if it does not exist
            add_column_to_table(table_name, ActiveRecord::Acts::Versioner::configurator[:default_versioned_created_at], :datetime)
            add_column_to_table(table_name, ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_at], :datetime)
            add_column_to_table(table_name, ActiveRecord::Acts::Versioner::configurator[:default_versioned_created_by], :integer)
            add_column_to_table(table_name, ActiveRecord::Acts::Versioner::configurator[:default_versioned_updated_by], :integer)


            # create versions table
            self.connection.create_table(versioned_table_name, create_table_options) do |t|
                    t.column versioned_foreign_key, :integer
                    t.column :action, :integer, :null => false, :default => 0
            end

            # clone the original table in order to create the versions table
            puts versioned_table_name
            not_versioned =  %w{id}
            self.versioned_columns.each do |col|
              unless not_versioned.include?(col.name)
                    self.connection.add_column versioned_table_name, col.name, col.type,
                            :limit => col.limit,
                            :default => col.default
              end
            end
          end

          def add_column_to_table(table, column, type)
            tabelle = self.connection.execute("show columns from #{table} like '#{column}'")
            
            do_add = true
            for res in tabelle
              do_add = false if column.to_s == res.first.to_s
            end
            if do_add
              self.connection.add_column table, column, type
            end
          end
          
          # Rake migration task to drop the versioned table
          def drop_versioned_table
            self.connection.drop_table versioned_table_name
          end
          
          # If a column is added call this method to adapt the versioned table
          def adapt_versioned_table
            not_versioned =  ["id", "action", versioned_foreign_key.to_s]
            versioned_columns = []
            self.connection.execute("show columns from #{versioned_table_name}").each { |col|
              versioned_columns << [col[0], col[1]] unless not_versioned.include?(col[0])
            }

            missing = []
            changed = []

            reset_columns = []
            self.connection.execute("show columns from #{table_name}").each { |col|
              reset_columns << [col[0], col[1]] unless not_versioned.include?(col[0])
            }

            reset_columns.each do |rc|
              found = versioned_columns.detect{ |wc| wc.first == rc.first }
              unless found.blank?
                changed << rc if rc.last.to_s != found.last.to_s
                versioned_columns.delete_if { |k| k.first == rc.first }
              else
                missing << rc
              end
            end
            
            # Add new column
            missing.each do |m|
              self.connection.add_column versioned_table_name, m.first, m.last
            end

            # Change column
            changed.each do |c|
              self.connection.change_column versioned_table_name, c.first, c.last
            end
            
            # Remove column
            versioned_columns.each do |vc|
              self.connection.remove_column versioned_table_name, vc.first
            end
          end
          
          # You can resurrect a destroyed entry by its versioned foreign key
          def resurrect(id)
             destroyed_version = self.versioned_class.where(self.versioned_foreign_key => id).last
             if destroyed_version && destroyed_version.action == 2
               model = self.new
               self.columns.map{|c| c.name}.each do |c|
                 model[c] = destroyed_version[c] unless c == "id"
                 model[c] = id if c == "id"
                 model[c] = Time.now if c == "updated_at"
               end
             model.save
             return model if model.errors.blank?
             end
          end
          
        end
      end

    end
  end
end

