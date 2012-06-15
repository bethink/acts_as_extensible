class CreateExtendedAttributeValues < ActiveRecord::Migration

  create_table :extended_attribute_values do |t|

    t.integer :extended_attribute_id

    [ :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean ].each do |i|
      t.send( i, "#{ i.to_s }_value" ) 
    end

    t.string  :symbol_type
    t.integer  :symbol_id

  end

  def self.down
    drop_table :extended_attribute_values
  end

end


#class CreateExtendedAttributeValues < ActiveRecord::Migration
#
#  def self.up
#    [ :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean ].each do |i|
#      add_column :extended_attribute_values, "#{ i.to_s }_value", i
#    end
#    
#    add_column :extended_attribute_values, :symbol_type, :string
#    add_column :extended_attribute_values, :symbol_id, :integer
#
#  end
#
#  def self.down
#
#    [ :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean ].each do |i|
#      remove_column :extended_attribute_values, "#{ i.to_s }_value"
#    end
#    
#    remove_column :extended_attribute_values, :symbol_type
#    remove_column :extended_attribute_values, :symbol_id
#
#  end
#
#end



# OLD DEFINITION
#class CreateExtendedAttributeValues < ActiveRecord::Migration
#  def self.up
#    create_table :extended_attribute_values do |t| 
#      t.integer :extended_attribute_id
#      t.string :value
#      t.timestamps
#    end
#    
#  end
#
#  def self.down
#    drop_table :extended_attribute_values
#  end
#end
