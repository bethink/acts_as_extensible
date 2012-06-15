class ModelAccessSchema < ActiveRecord::Base
  
  ['model_name', 'relationship_name', 'attr_name', 'method_name', 'access_model'].each do |field_name|
    named_scope "by_#{field_name}", lambda{|name| ( name.blank? ? {} : { :conditions => ["#{field_name} = ?", name ] } ) }
  end
  
  named_scope :limit, lambda{|limit| { :limit => limit } }
  
  def self.update_create( sinfo )
  
    access_model_name = sinfo[:access_model].blank? ? nil : sinfo[:access_model].to_s.classify

    if( model_access_schema = ModelAccessSchema.by_access_model( access_model_name ).by_model_name( sinfo[:model_name] ).by_relationship_name( sinfo[:relationship_name] ).by_attr_name( sinfo[:attr_name] ).by_method_name( sinfo[:method_name] ).limit(1).first )
      model_access_schema.update_attributes( sinfo )
      model_access_schema
    else
      ModelAccessSchema.create( :model_name => sinfo[:model_name], :access_model => access_model_name, :relationship_name => sinfo[:relationship_name], :attr_name => sinfo[:attr_name], :method_name =>  sinfo[:method_name] )
    end

  end  
  
  # Return true / false
  
  # parameter: object - any model object which act_as_extensible defined
  #            m_name - Method name which has missed in model and extended_attribute_schema
  
  # First it checks the object's relationship. If the attr_name not exists then it object try with method_name.
  # method_name : method_name should be defined in object's class as instance method. It should return false or nil as negative reponse.
  #               Other than false and nil everything is positive response
  
  def accessible_in_model?( object, m_name, value, args )

    if( self.relationship_name and self.attr_name )

      children = get_children( object, m_name, args )
      
      children.collect do |child|
        child.send( self.method_name ).to_attr_name
      end.include?( m_name )
        
    elsif self.method_name
      !!object.send( self.method_name, m_name, value, args )
    else
      false
    end
      
  end
  
  
  def get_children( object, m_name, args )

    rname = self.relationship_name

    if object.new_record?

      rname_id = rname.relationship_id_attr
      
      if args[rname]
        args[rname]
      elsif args[rname_id]
        find_method = ( args[rname_id] =~ /s$/ ) ? :find_all_by_id : :find_by_id 
        self.access_model.constantize.send( find_method, args[rname_id] )
      end
      
    else
      object.send( self.relationship_name )
    end
  end
    
end