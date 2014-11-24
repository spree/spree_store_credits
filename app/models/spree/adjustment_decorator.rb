Spree::Adjustment.class_eval do
  scope :store_credits, -> { where(source_type: 'Spree::StoreCredit') }
end