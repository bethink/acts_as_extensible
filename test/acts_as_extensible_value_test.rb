require 'rubygems'
require 'attr_encrypted'
require 'ruby-debug'

require File.dirname(__FILE__) + '/../test_helper'


class ActsAsExtensibleValueTest < Test::Unit::TestCase
  
  context "section.save_question( quesions )" do   
    
    setup do
      
      @options = [ 'Benz', 'BMW', 'Audi', 'Volvo', 'Lexis', 'Porsche', 'Honda', 'Skoda', 'VolsWagon' ].collect do |name|
        Option.create( :name => name )
      end

      @ext_attr_schema = [ :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean ].collect do |name|
        ExtendedAttributesSchema.create( :attr_name => "#{ name.to_s }_attr", :model_type => 'Article', :data_type => name, :symbol_type => nil )
      end
      @ext_attr_schema << ExtendedAttributesSchema.create( :attr_name => "single_attr", :model_type => 'Article', :data_type => 'symbolSingle', :symbol_type => 'Option' )
      @ext_attr_schema << ExtendedAttributesSchema.create( :attr_name => "multiple_attr", :model_type => 'Article', :data_type => 'symbolMultiple', :symbol_type => 'Option' )

      @article = Article.first
      @ext_attr_schema.each do | ext_attr_schema |
        ExtendedAttribute.create( :model_id => @article.id, :extended_attribute_schema => ext_attr_schema )
      end
      
    end
    
    should "Check the getter values" do
      
      
      
    end
    
  end    
  
end