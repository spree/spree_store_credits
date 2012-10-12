class Spree::StoreCredit < ActiveRecord::Base
  attr_accessible :amount, :reason, :remaining_amount, :user_id

  validates :amount, :presence => true, :numericality => true
  validates :reason, :presence => true
  validates :user, :presence => true

  belongs_to :user, :class_name => Spree.user_class.to_s, :foreign_key => 'user_id'
end
