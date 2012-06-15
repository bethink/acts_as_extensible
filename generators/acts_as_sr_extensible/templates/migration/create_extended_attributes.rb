class CreateExtendedAttributes < ActiveRecord::Migration
  def self.up
    create_table :extended_attributes do |t|
      t.string :key,:value,:model_type
      t.integer :model_id, :extended_attributes_schema_id
      t.timestamps
    end
  end
  
  def self.down
    drop_table :extended_attributes
  end
end


#class CreateExtendedAttributes < ActiveRecord::Migration
#  def self.up
#    add_column :extended_attributes, :extended_attributes_schema_id, :integer
#  end
#  
#  def self.down
#    remove_column :extended_attributes, :extended_attributes_schema_id
#  end
#end