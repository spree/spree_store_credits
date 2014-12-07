require 'bigdecimal'

FactoryGirl.define do

  factory :store_credit, class: Spree::StoreCredit do
    amount { BigDecimal.new(rand * 100, 2) }
    reason { SecureRandom.hex(5) }
    user
  end

  factory :give_store_credit_action, class: Spree::Promotion::Actions::GiveStoreCredit do
    association :promotion

    after(:create) do |action|
      action.set_preference(:amount, 1_234.56)
      action.save!
    end
  end

  factory :promotion_for_store_credits, parent: :promotion do

    after(:create) do |promotion|
      promotion.promotion_actions [create(:give_store_credit_action, promotion: promotion)]
      promotion.save!
    end
  end

  factory :give_store_credit_as_percentage_action, class: Spree::Promotion::Actions::GiveStoreCreditAsPercentage do
    association :promotion

    after(:create) do |action|
      action.set_preference(:flat_percent, 15)
      action.save!
    end
  end

  factory :promotion_for_store_credits_as_percentage, parent: :promotion do

    after(:create) do |promotion|
      promotion.promotion_actions [create(:give_store_credit_as_percentage_action, promotion: promotion)]
      promotion.save!
    end
  end
end
