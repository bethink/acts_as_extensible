class CreateExtendedAttributesSchemas < ActiveRecord::Migration
   def self.up
     create_table :extended_attributes_schemas do |t|
       t.string :attr_name,:model_type,:validation, :data_type, :symbol_type
       t.boolean :mandatory
       t.timestamps
    end
  end

  def self.down
    drop_table :extended_attributes_schemas
  end
end

#class CreateExtendedAttributesSchemas < ActiveRecord::Migration
#  
#  def self.up
#    add_column :extended_attributes_schemas, :symbol_type, :string
#    add_column :extended_attributes_schemas, :mandatory, :boolean  
#  end
#  
#  def self.down
#    remove_column :extended_attributes_schemas, :symbol_type
#    remove_column :extended_attributes_schemas, :mandatory    
#  end
#  
#end