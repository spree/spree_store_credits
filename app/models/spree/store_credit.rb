module Spree
  class StoreCredit < ActiveRecord::Base
    validates :amount, :presence => true, :numericality => true
    validates :reason, :presence => true
    validates :user, :presence => true

    belongs_to :user
    attr_accessible :amount, :remaining_amount, :reason, :user_id
  end
end
