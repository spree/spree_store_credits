RSpec.describe Spree::Promotion::Actions::GiveStoreCreditAsPercentage, type: :model do

  let(:user)      { create(:user, email: 'spree@example.com') }
  let(:order)     { create(:order_with_line_items, line_items_count: 1, user: user) }
  let(:promotion) { create(:promotion) }
  let(:action)    { described_class.new }
  let(:payload)   { { order: order, user: user } }

  context '.perform' do
    before do
      promotion.promotion_actions = [action]
      allow(action).to receive_messages(promotion: promotion)
    end

    it 'does not apply a store credit if the flat percent is 0' do
      order.line_items = [
        create(:line_item, price: 0.0, quantity: 1),
        create(:line_item, price: 0.0, quantity: 1)
      ]
      action.perform(payload)
      expect(user.store_credits.count).to be(0)
    end

    it 'does not apply a store credit if the amount is 0' do
      action.calculator.preferred_flat_percent = 0
      action.perform(payload)
      expect(user.store_credits.count).to be(0)
    end

    it 'creates a store credit with correct positive amount' do
      order.shipments.create!(cost: 10)
      action.perform(payload)
      expect(user.store_credits.count).to be(1)
      expect(user.store_credits.first.amount.to_f).to be(1.0)
    end

    it 'does not create a store credit when order already has produce one from this promotion' do
      order.shipments.create!(cost: 10)
      action.perform(payload)
      action.perform(payload)
      expect(user.store_credits.count).to be(1)
      expect(user.store_credits.first.amount.to_f).to be(1.0)
    end

    it 'calculates the percentage with respect the order items total price' do
      order.shipments.create!(cost: 10)
      order.line_items = [
        create(:line_item, price: 100.0, quantity: 2),
        create(:line_item, price: 50.0, quantity: 1)
      ]
      action.perform(payload)
      expect(user.store_credits.count).to be(1)
      expect(user.store_credits.first.amount.to_f).to be(25.0)
    end

    it 'allows to change preferred percentage and use that for the order items total price' do
      order.shipments.create!(cost: 10)
      action.preferred_flat_percent = 15
      action.save
      order.line_items = [
        create(:line_item, price: 100.0, quantity: 2),
        create(:line_item, price: 50.0, quantity: 1)
      ]
      action.perform(payload)
      expect(user.store_credits.count).to be(1)
      expect(user.store_credits.first.amount.to_f).to be(37.5)
    end
  end
end
