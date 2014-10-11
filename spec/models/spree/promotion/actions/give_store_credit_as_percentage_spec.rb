require 'spec_helper'

RSpec.describe Spree::Promotion::Actions::GiveStoreCreditAsPercentage, :type => :model do
  let(:user) { create(:user, :email => "spree@example.com") }
  let(:order) { create(:order_with_line_items, :line_items_count => 1, :user => user) }
  let(:promotion) { create(:promotion) }
  let(:action) { Spree::Promotion::Actions::GiveStoreCreditAsPercentage.new }
  let(:payload) { { order: order,  user: user } }

  # From promotion spec:
  context "#perform" do
    before do
      promotion.promotion_actions = [action]
      allow(action).to receive_messages(:promotion => promotion)
    end

    it "does not apply a store credit if the flat percent is 0" do
      order.line_items = [create(:line_item, :price => 0.0, :quantity => 1),
                          create(:line_item, :price => 0.0, :quantity => 1)]
      action.perform(payload)
      expect(user.store_credits.count).to eq(0)
    end

    it "does not apply a store credit if the amount is 0" do
      action.calculator.preferred_flat_percent = 0
      action.perform(payload)
      expect(user.store_credits.count).to eq(0)
    end

    it "should create a store credit with correct positive amount" do
      order.shipments.create!(:cost => 10)

      action.perform(payload)
      expect(user.store_credits.count).to eq(1)
      expect(user.store_credits.first.amount.to_i).to eq(1)
    end

    it "should not create a store credit when order already has produce one from this promotion" do
      order.shipments.create!(:cost => 10)
      action.perform(payload)
      action.perform(payload)
      expect(user.store_credits.count).to eq(1)
      expect(user.store_credits.first.amount.to_i).to eq(1)
    end

    it "should calculate the percentage with respect the order items total price" do
      order.shipments.create!(:cost => 10)
      order.line_items = [create(:line_item, :price => 100.0, :quantity => 2),
                          create(:line_item, :price => 50.0, :quantity => 1)]
      action.perform(payload)
      expect(user.store_credits.count).to eq(1)
      expect(user.store_credits.first.amount.to_i).to eq(25)
    end

  end

end