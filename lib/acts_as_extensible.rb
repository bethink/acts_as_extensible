module ActsAsExtensible
  
  def self.included(base)
    base.extend(ClassMethods)
    #      class << base
    #        alias_method_chain :method_missing, :extensible
    #      end
  end
  
  module ClassMethods
    
    def acts_as_extensible(options = {})
      
      has_many :extended_attributes, :as=> :model, :dependent => :destroy
      
      manipulate_schema_info options[:schema_info]
      
      create_dynamic_attributes(self)
      
      extendedNamedScope
      
      #      self.class_eval do
      #      end
      
      class_eval <<-EOV
        include ActsAsExtensible::InstanceMethods
      EOV
      
    end
    
    # Creates setter and getter methods
    def create_dynamic_attributes(model)
      ext_attrs = ExtendedAttributesSchema.find_all_by_model_type(self.to_s)
      
      ext_attrs.each do |ext_attr|
        class_eval do 
          
          define_method "#{ext_attr.attr_name}=" do |value| 
            set_attr_value( ext_attr.attr_name, value )
          end
          
          define_method "#{ext_attr.attr_name}" do
            attributes[ext_attr.attr_name] ? return_value_with_data_type(ext_attr.data_type.intern,attributes[ext_attr.attr_name]) : nil  
          end
          
          define_method "#{ext_attr.attr_name}?" do
            attributes[ext_attr.attr_name] ? true : false
          end  
          
        end
      end
    end
    
    
    #    Create entry in ExtendedAttributesSchema when call act_as_extensible in a model    
    def manipulate_schema_info( schema_info )
      
      schema_info = schema_info_to_array( schema_info )
      
      schema_info.each do |info|
        
        info.update({:model_type=>name.to_s})
        ext_attr_obj = ExtendedAttributesSchema.find_by_model_type_and_attr_name( name.to_s, info[:attr_name] )
        if ext_attr_obj
          if info.collect{|key,value| ext_attr_obj.send(key) == value }.include?(false)       
            ext_attr_obj.update_attributes(info)
          end  
        else
          ExtendedAttributesSchema.create(info)   
        end
      end
    end
    
    def schema_info_to_array( schema_info )
     ( schema_info.is_a?(Array) ? schema_info : [ schema_info ] ).compact
    end

    def extendedNamedScope
      
      #     To find the model object based on given dynamic attribute and value
      #     Ex. User.by_dynamic_attr('dynamic_attribute_name', 'value')
      #         User.by_dynamic_attr('dynamic_attribute_name', ['val1', 'val2', 'val3'])
      
      self.class_eval do
        
        named_scope :by_extended_attr, lambda{|attr_name, value|
          
          schema = ExtendedAttributesSchema.by_attr_name( attr_name ).by_model_type( self.name ).first
          
          if schema and !value.blank?
            data_type = schema.data_type
            
            if schema.data_type =~ /^symbol/
              symbol_type = schema.symbol_type.tableize
              {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id join #{ symbol_type } on #{ symbol_type }.id = extended_attribute_values.symbol_id",
                :conditions => ["extended_attribute_values.symbol_type = ? and #{ symbol_type }.name = ? and extended_attributes.extended_attributes_schema_id = ?", schema.symbol_type, value, schema.id ]
              }
            else
              {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id",
                :conditions => ["extended_attribute_values.#{ data_type }_value in (?) and extended_attributes.extended_attributes_schema_id = ?", value.to_a, schema.id ]
              }
            end
            
          else
            { :conditions => ['false'] }
          end
          
        }
        
        #     To find the model object based on given substring dynamic attribute and value
        #     Ex. User.by_dynamic_attr('dynamic_attribute_name', '%value%')
        #     Ex. User.by_dynamic_attr('dynamic_attribute_name', '%value')
        #     Ex. User.by_dynamic_attr('dynamic_attribute_name', 'value%')
        
        named_scope :substring_match, lambda{|attr_name, str|
          
          schema = ExtendedAttributesSchema.by_attr_name( attr_name ).by_model_type( self.name ).first
          
          if schema and !str.gsub(/%/,'').blank?
            data_type = schema.data_type
            
            if schema.data_type =~ /^symbol/
              symbol_type = schema.symbol_type.tableize
              {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id join #{ symbol_type } on #{ symbol_type }.id = extended_attribute_values.symbol_id",
                :conditions => ["extended_attribute_values.symbol_type = ? and UPPER( #{ symbol_type }.name ) like UPPER(?) and extended_attributes.extended_attributes_schema_id = ?", schema.symbol_type, "#{str}%", schema.id ]
              }
            else
              {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id",
                :conditions => ["UPPER( extended_attribute_values.#{ data_type }_value ) like UPPER(?) and extended_attributes.extended_attributes_schema_id = ?", str, schema.id ]
              }
            end
            
          else
            { :conditions => ['false'] }
          end
          
        }
        
        def self.by_extended_attr_start_at( attr_name, str )
          substring_match( attr_name, "#{str}%" )
        end
        
        def self.by_extended_attr_end_at( attr_name, str )
          substring_match( attr_name, "%#{str}" )
        end
        
        def self.by_extended_attr_substring( attr_name, str )
          substring_match( attr_name, "%#{str}%" )
        end
        
        
        # To order the model object based on given dynamic attribute
        # It will order the model objects in which the dynamic attribute value occurs
        # Ex. User.by_dynamic_attr('dynamic_attribute_name', 'asc')
        #     User.by_dynamic_attr('dynamic_attribute_name', 'desc')
        #     User.by_dynamic_attr('dynamic_attribute_name', nil)
        
        named_scope :order_by_extended_attr, lambda{|attr_name, order|
          
          schema = ExtendedAttributesSchema.by_attr_name( attr_name ).by_model_type( self.name ).first
          
          if schema
            data_type = schema.data_type
            
            if schema.data_type =~ /^symbol/
              symbol_type = schema.symbol_type.tableize

              { :conditions => ['false'] }

              {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id join #{ symbol_type } on #{ symbol_type }.id = extended_attribute_values.symbol_id",
                :conditions => ["extended_attribute_values.symbol_type = ? and #{ symbol_type }.name is not ? and extended_attributes.extended_attributes_schema_id = ?", schema.symbol_type, nil, schema.id],
                :order => "#{ symbol_type }.name #{ order || 'asc' }"
              }
            else
              {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id",
                :conditions => ["extended_attribute_values.#{ data_type }_value is not ? and extended_attributes.extended_attributes_schema_id = ?", nil, schema.id],
                :order => "extended_attribute_values.#{ data_type }_value #{ order || 'asc' }"
              }
            end
            
          else
            { :conditions => ['false'] }
          end
          
        }
        
        # Common method for date time manupulations
        # operator can be >, <, <=, >=, == or !=  in the form of string
        # Can't use between operation
        # to use between use 'date_time_between' named scope
        
        named_scope :date_time_condition, Proc.new{|attr_name, date, operator, order|
          
          schema = ExtendedAttributesSchema.by_attr_name( attr_name ).by_model_type( self.name ).first
          
          if schema and !( schema.data_type =~ /^symbol/ )
            
            data_type = schema.data_type
            {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id",
                :conditions => ["extended_attribute_values.#{ data_type }_value #{ operator } ? and extended_attributes.extended_attributes_schema_id = ?", date.to_time.beginning_of_day, schema.id],
                :order => "extended_attribute_values.#{ data_type }_value #{ order || 'asc' }"
            }
          else
            { :conditions => ['false'] }
          end
          
        }
        
        # To find the objects of future dated based on date/time extended field
        def self.by_ext_future_date( attr_name, date, order )
          date_time_condition( attr_name, date, '>=' ,order )
        end
        
        # To find the objects of past dated based on date/time extended field
        def self.by_ext_past_date( attr_name, date, order )
          date_time_condition( attr_name, date, '<' ,order )
        end
        
        # To use between operator for date/time type fields
        named_scope :ext_date_time_between, lambda{|attr_name, from, to, order|
          
          schema = ExtendedAttributesSchema.by_attr_name( attr_name ).by_model_type( self.name ).first
          
          if schema and !( schema.data_type =~ /^symbol/ )
            
            data_type = schema.data_type
            {
                :joins => "join extended_attributes on articles.id = extended_attributes.model_id join extended_attribute_values on extended_attributes.id = extended_attribute_values.extended_attribute_id",
                :conditions => ["extended_attribute_values.#{ data_type }_value between ? and ? and extended_attributes.extended_attributes_schema_id = ?", from.to_time.beginning_of_day, to.to_time.end_of_day, schema.id],
                :order => "extended_attribute_values.#{ data_type }_value #{ order || 'asc' }"
            }
          else
            { :conditions => ['false'] }
          end
          
        }
        
      end    
      
    end
    
  end
  
  module InstanceMethods
    
    def extended_attrs
      
      self.extended_attributes.inject({}) do |ext_attr,ext_obj|
        ext_attr[ext_obj.attr_name]=ext_obj.value
        ext_attr
      end
    end
    
    def attributes
      super.merge!(extended_attrs)
    end
    
    def return_value_with_data_type(type,value)
      return nil if value.nil?
      case type
        when :string    then value
        when :text      then value
        when :integer   then value.to_i rescue value ? 1 : 0
        when :float     then value.to_f
        when :decimal   then ActiveRecord::ConnectionAdapters::Column.value_to_decimal(value)
        when :datetime  then ActiveRecord::ConnectionAdapters::Column.string_to_time(value)
        when :timestamp then ActiveRecord::ConnectionAdapters::Column.string_to_time(value)
        when :time      then ActiveRecord::ConnectionAdapters::Column.string_to_dummy_time(value)
        when :date      then ActiveRecord::ConnectionAdapters::Column.string_to_date(value)
        when :binary    then ActiveRecord::ConnectionAdapters::Column.binary_to_string(value)
        when :boolean   then ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
      else value
      end
    end
    
    # ====================================================      
    
    def method_missing(method_id, *args, &block)
      method_name = method_id.to_s
      if self.class.private_method_defined?(method_name)
        raise NoMethodError.new("Attempt to call private method", method_name, args)
      end
      
      # If we haven't generated any methods yet, generate them, then
      # see if we've created the method we're looking for.
      if !self.class.generated_methods?
        self.class.define_attribute_methods
        if self.class.generated_methods.include?(method_name)
          return self.send(method_id, *args, &block)
        end
      end
      
      if self.class.primary_key.to_s == method_name
        id
      elsif md = self.class.match_attribute_method?(method_name)
        attribute_name, method_type = md.pre_match, md.to_s
        if @attributes.include?(attribute_name)
          __send__("attribute#{method_type}", attribute_name, *args, &block)
        else            
          
          if setter?( method_name )
           ( set_attr_value( method_name, args ) || super ) 
          else
            if( value = get_attr_value_from_ext_attr( method_name, args ) ) 
              value
            else
             ( find_attr_in_schema( method_name ) ? nil : super ) 
            end
          end
          
        end
      elsif @attributes.include?(method_name)
        read_attribute(method_name)
      else
        if setter?( method_name )
         ( set_attr_value( method_name, args ) || super ) 
        else
          if( value = get_attr_value_from_ext_attr( method_name, args ) ) 
            value
          else
           ( find_attr_in_schema( method_name ) ? nil : super ) 
          end
        end
      end    
    end
    
    # This method should be overwritten for Additional Data implementation
    def set_attr_value( m_name, args )
      
      dup_m_name = m_name.gsub(/=$/, '')
      if( extended_attribute = find_in_extended_attr( dup_m_name ) )
        extended_attribute.update_attributes( :values => args )
      elsif( schema = find_attr_in_schema( dup_m_name ) )
        self.extended_attributes.build( :extended_attributes_schema => schema, :values => args )
      end
      
    end
    
    # To fetch the value from the 
    def get_attr_value_from_ext_attr( m_name, args )
      
      if self.new_record?
        
        value = nil
        
        self.extended_attributes.each do |extended_attr|
          value = ( extended_attr.value.blank? ? nil : extended_attr.value ) if( extended_attr.attr_name == m_name )
        end
        value
        
      else
        extended_attribute = find_in_extended_attr( m_name )
        extended_attribute.value if extended_attribute
      end
      
    end
    
    # To check whether it is setter method or not
    def setter?( m_name )
     ( m_name.to_s.strip =~/(.+)=$/ ) ? true : false
    end
    
    # Finds an entry in the Extended Attribute table for the given method name
    def find_in_extended_attr( m_name )
      schema = find_attr_in_schema( m_name )
      self.extended_attributes.find_by_extended_attributes_schema_id( schema.id ) unless schema.blank?
    end
    
    def find_attr_in_schema( m_name )
      ExtendedAttributesSchema.by_attr_name( m_name ).by_model_type( self.class.to_s ).first
    end
    
    
    public
    def attributes=(new_attributes, guard_protected_attributes = true)
      
      return if new_attributes.nil?
      attributes = new_attributes.dup
      attributes.stringify_keys!
      
      multi_parameter_attributes = []
      attributes = remove_attributes_protected_from_mass_assignment(attributes) if guard_protected_attributes
      
      attributes.each do |k, v|
        if k.include?("(")
          multi_parameter_attributes << [ k, v ]
        else
          
          if respond_to?(:"#{k}=") || find_attr_in_schema( k )
            send(:"#{k}=", v)
          else
            raise(ActiveRecord::UnknownAttributeError, "unknown attribute: #{k}")
          end
          
        end
      end
      
      assign_multiparameter_attributes(multi_parameter_attributes)
    end

  end    
  
end

module StringUtil
  def to_attr_name
    self.downcase.gsub(/[^\s\w]/, '').strip.gsub(/\s+/, '_')
  end
  
  def relationship_id_attr
    self.match( /s$/ ) ? "#{ self.gsub(/s$/, '') }_ids" : "#{ self }_id"
  end
end

String.class_eval do
  include StringUtil
end

ActiveRecord::Base.send(:include, ActsAsExtensible)
