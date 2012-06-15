class CreateModelAccessSchemas < ActiveRecord::Migration
  def self.up
    create_table :model_access_schemas do |t|
      t.string :model_name, :access_model, :relationship_name, :attr_name, :method_name
      t.timestamps
    end
  end
  
  def self.down
    drop_table :model_access_schemas
  end
end