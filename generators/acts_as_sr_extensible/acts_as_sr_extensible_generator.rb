class ActsAsSrExtensibleGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template "migration/create_extended_attributes_schemas.rb", "db/migrate", :migration_file_name => 'create_extended_attributes_schemas'
      m.migration_template "migration/create_extended_attributes.rb", "db/migrate", :migration_file_name => 'create_extended_attributes'
    end
  end
  
  def self.next_migration_number(dirname)
     if ActiveRecord::Base.timestamped_migrations
       Time.now.utc.strftime("%Y%m%d%H%M%S")
     else
       "%.3d" % (current_migration_number(dirname) + 1)
     end
   end
 
end
