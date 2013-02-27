class StoreCreditMinimumValidator < ActiveModel::Validator
  include ActionView::Helpers::NumberHelper

  def validate(record)
    if Spree::Config[:use_store_credit_minimum] and record.item_total < Spree::Config[:use_store_credit_minimum].to_f and record.store_credit_amount > 0 and record.errors.empty?
      record.errors.add :base, I18n.t("errors.messages.store_credit_minimum_order_not_reach", :amount => number_to_currency(Spree::Config[:use_store_credit_minimum].to_f))
    end
  end
end
