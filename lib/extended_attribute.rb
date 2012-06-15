require 'ruby-debug'

class ExtendedAttribute < ActiveRecord::Base
  belongs_to :model, :polymorphic => true
  has_many :extended_attribute_values, :dependent => :destroy
  belongs_to :extended_attributes_schema
  
  [ :attr_name, :model_type, :validation, :data_type, :symbol_type ].each do |method|
    delegate method, :to => :extended_attributes_schema
  end
  
  def key
    self.extended_attributes_schema.attr_name
  end
  
  def value_attr_name
    "#{ data_type }_value"
  end
  
  def value
    
    if self.data_type =~ /^symbol/
      self.symbol_value
    else
      ext_attr_value = self.extended_attribute_values.first
      ext_attr_value.send( self.value_attr_name ) if ext_attr_value
    end
    
  end

  def values=( values )
    
    attr_values = simplify_values( values )
    
    self.extended_attribute_values.destroy_all
    
    if self.data_type.eql?( 'symbolMultiple' )
      
      attr_values.each do |attr_value|
        self.extended_attribute_values.build( :symbol => get_symbol( attr_value ) )
      end
      
    elsif self.data_type.eql?( 'symbolSingle' )
      
      self.extended_attribute_values.build( :symbol => get_symbol( attr_values.first ) )
      
    else
      
      self.extended_attribute_values.build( self.value_attr_name => attr_values.first )
      
    end
    
  end
  
  def symbol_value
    
    if self.data_type.eql? 'symbolMultiple'
      ext_attr_values = self.extended_attribute_values
      ext_attr_values.collect(&:symbol).compact
    else
      ext_attr_value = self.extended_attribute_values.first
      ext_attr_value.symbol
    end
    
  end
  
  def symbol_as_constant
    symbol_type = self.symbol_type
    return( nil ) if symbol_type.blank?
    constant = symbol_type.classify.constantize
  end
  
  def get_symbol( obj_id )
    constant = symbol_as_constant
    constant.find_by_id( obj_id ) if constant
  end
  
  def simplify_values( values )
    attr_values = ( values.is_a?( Array ) ? values : [ values ] ).flatten.compact
    attr_values.delete_if(&:blank?)
  end
  
  #  def old_value
  #
  #    values = self.extended_attribute_values
  #
  #    if values.length <= 1
  #      ( values.first and values.first.value )
  #    else
  #      values.collect(&:value)
  #    end
  #    
  #  end
  
  #  def values=( values )
  #
  #    pvalues = ( values.is_a?( Array ) ? values : [ values ] ).flatten.compact
  #    self.extended_attribute_values.destroy_all
  #    
  #    pvalues.each do |value|
  #      self.extended_attribute_values.build( :value => value )
  #    end
  #    
  #  end
  
  #  def entity_detail(receiver_name)
  #      receiver_name.constantize.find(self.model_id)
  #  end
  
end
