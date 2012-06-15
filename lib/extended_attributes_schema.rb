class ExtendedAttributesSchema < ActiveRecord::Base
  has_and_belongs_to_many :options
  
  validates_presence_of :attr_name
  
  [ :attr_name, :model_type, :data_type ].each do |name|
    named_scope "by_#{ name }", lambda{|value| { :conditions => { name => value } } }
  end
  
end