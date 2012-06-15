class ExtendedAttributeValue < ActiveRecord::Base
  belongs_to :extended_attribute
  belongs_to :symbol, :polymorphic => true
end