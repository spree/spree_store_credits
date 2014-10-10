RSpec.describe Spree::Order, type: :model do

  let(:user)          { create(:user) }
  let!(:store_credit) { create(:store_credit, user: user, amount: 45.00, remaining_amount: 45.00) }
  let(:line_item)     { mock_model(Spree::LineItem, variant: double('variant'), quantity: 5, price: 10) }
  let(:order)         { create(:order, user: user) }

  before do
    reset_spree_preferences { |config| config.use_store_credit_minimum = 0 }
  end

    context "process_store_credit" do
      before do
        allow(order).to receive(:user).and_return(user)
        allow(order).to receive(:total).and_return(50)
      end

    it 'creates store credit adjustment when user has sufficient credit' do
      order.store_credit_amount = 5.0
      order.save
      expect(order.adjustments.store_credits.size).to be(1)
      expect(order.store_credit_amount).to be(5.0)
    end

    it 'only create adjustment with amount equal to users total credit' do
      order.store_credit_amount = 50.0
      order.save
      expect(order.store_credit_amount.to_f).to be(45.00)
    end

    it 'only create adjustment with amount equal to order total' do
      allow(user).to receive_messages(store_credits_total: 100.0)
      order.store_credit_amount = 90.0
      order.save
      expect(order.store_credit_amount.to_f).to be(50.00)
    end

    it 'does not create adjustment when user does not have any credit' do
      allow(user).to receive_messages(store_credits_total: 0.0)
      order.store_credit_amount = 5.0
      order.save
      expect(order.adjustments.store_credits.count).to be(0)
      expect(order.store_credit_amount.to_f).to be(0.0)
    end

    it 'updates order totals if credit is applied' do
      expect(order.updater).to receive(:update_totals).once
      order.store_credit_amount = 5.0
      order.save
    end

    it 'updates payment amount if credit is applied' do
      allow(order).to receive_message_chain(:unprocessed_payments, first: double('payment', payment_method: double('payment method', payment_profiles_supported?: true)))
      expect(order.unprocessed_payments.first).to receive(:amount=)
      order.store_credit_amount = 5.0
      order.save
    end

    it 'creates negative adjustment' do
      order.store_credit_amount = 5.0
      order.save
      expect(order.adjustments.first.amount.to_f).to be(-5.0)
    end

    it 'processes credits if order total is already zero' do
      allow(order).to receive_messages(total: 0)
      order.store_credit_amount = 5.0
      expect(order).to receive(:process_store_credit)
      order.save
      expect(order.adjustments.store_credits.count).to be(0)
      expect(order.store_credit_amount.to_f).to be(0.0)
    end

    context 'with an existing adjustment' do
      before { order.adjustments.store_credits.create(label: I18n.t(:store_credit), amount: -10) }

      it 'decreases existing adjustment if specific amount is less than adjustment amount' do
        order.store_credit_amount = 5.0
        order.save
        expect(order.adjustments.store_credits.count).to be(1)
        expect(order.store_credit_amount.to_f).to be(5.0)
      end

      it 'increases existing adjustment if specified amount is greater than adjustment amount' do
        order.store_credit_amount = 25.0
        order.save
        expect(order.adjustments.store_credits.count).to be(1)
        expect(order.store_credit_amount.to_f).to be(25.0)
      end

      it 'destroys the adjustment if specified amount is zero' do
        order.store_credit_amount = 0.0
        order.save
        expect(order.adjustments.store_credits.count).to be(0)
        expect(order.store_credit_amount.to_f).to be(0.0)
      end

      it 'decreases existing adjustment when existing credit amount is equal to the order total' do
        allow(order).to receive_messages(total: 10)
        order.store_credit_amount = 5.0
        order.save
        expect(order.adjustments.store_credits.count).to be(1)
        expect(order.store_credit_amount.to_f).to be(5.0)
      end
    end
  end

  context '.store_credit_amount' do
    it 'returns total for all store credit adjustments applied to order' do
      order.adjustments.store_credits.create(label: I18n.t(:store_credit), amount: -10)
      order.adjustments.store_credits.create(label: I18n.t(:store_credit), amount: -5)
      expect(order.store_credit_amount.to_f).to be(15.0)
    end
  end

  context '.consume_users_credit' do
    let(:store_credit_1) { mock_model(Spree::StoreCredit, amount: 100, remaining_amount: 100) }
    let(:store_credit_2) { mock_model(Spree::StoreCredit, amount: 10, remaining_amount: 5) }
    let(:store_credit_3) { mock_model(Spree::StoreCredit, amount: 60, remaining_amount: 50) }
    let(:user_with_credits) do
      user = create(:user)
      user.store_credits.create(amount: 100, remaining_amount: 100, reason: 'A')
      user.store_credits.create(amount: 60, remaining_amount: 55, reason: 'B')
      user
    end

    before { allow(order).to receive_messages(completed?: true, store_credit_amount: 35, total: 50) }

    it 'reduces remaining amount on a single credit when that credit satisfies the entire amount' do
      allow(user).to receive_messages(store_credits: [store_credit_1])
      expect(store_credit_1).to receive(:remaining_amount=).with(65)
      expect(store_credit_1).to receive(:save)
      order.send(:consume_users_credit)
    end

    it 'reduces remaining amount on a multiple credits when a single credit does not satisfy the entire amount' do
      allow(order).to receive_messages(store_credit_amount: 55)
      allow(user).to receive_messages(store_credits: [store_credit_2, store_credit_3])
      expect(store_credit_2).to receive(:update_attribute).with(:remaining_amount, 0)
      expect(store_credit_3).to receive(:update_attribute).with(:remaining_amount, 0)
      order.send(:consume_users_credit)
    end

    it 'calls consume_users_credit after transition to complete' do
      user = user_with_credits
      new_order = Spree::Order.new(user: user)
      allow(new_order).to receive_messages(store_credit_amount: 55)
      new_order.state = :confirm
      new_order.next!
      expect(new_order.state).to eq('complete')
      expect(user.store_credits_total.to_f).to be(100.00)
    end

    # regression
    it 'does nothing on guest checkout' do
      allow(order).to receive_messages(user: nil)
      expect {
        order.send(:consume_users_credit)
      }.to_not raise_error
    end
  end

  describe '.ensure_sufficient_credit' do
    let!(:order) { create(:order_with_line_items, payment_state: 'paid', state: 'complete', store_credit_amount: 35, user: user) }
    let!(:payment) { create(:payment, order: order, amount: 40, state: 'completed') }

    before do
      order.adjustments.store_credits.create(label: I18n.t(:store_credit), amount: -10, eligible: true)
      order.update!
    end

    it 'does nothing when user has credits' do
      order.send(:ensure_sufficient_credit)
      expect(order.adjustments.store_credits).not_to receive(:destroy_all)
      expect(order).not_to receive(:update!)
    end

    context 'when user no longer has sufficient credit to cover entire credit amount' do
      before do
        store_credit.remaining_amount = 0.0
        store_credit.save!
        user.reload
      end

      it 'destroys all store credit adjustments' do
        expect(order.adjustment_total.to_f).to be(-10.0)
        expect(order.total.to_f).to be(100.0)
        expect(order.payment_total.to_f).to be(40.0)
        order.send(:ensure_sufficient_credit)
        expect(order.adjustments.store_credits.size).to be(0)
        order.reload
        expect(order.adjustment_total.to_f).to be(0.0)
      end

      it "updates the order's payment state" do
        expect(order.payment_state).to eq('paid')
        order.send(:ensure_sufficient_credit)
        order.reload
        expect(order.payment_state).to eq('balance_due')
      end
    end
  end

  context '.process_payments!' do
    it 'returns false when total is greater than zero and payments are empty' do
      allow(order).to receive_messages(unprocessed_payments: [])
      expect(order.process_payments!).to be_nil
    end

      it "should process payment when total is zero and payments is not empty" do
        allow(order).to receive(:unprocessed_payments).and_return([mock_model(Payment)])
        expect(order).to receive(:process_payments_without_credits!)
        order.process_payments!
      end

    end

  describe 'when minimum item total is set' do
    before do
      allow(order).to receive_messages(item_total: 50)
      order.instance_variable_set(:@store_credit_amount, 25)
    end

    context 'when item total is less than limit' do
      before do
        reset_spree_preferences { |config| config.use_store_credit_minimum = 100 }
      end

      it 'is invalid' do
        expect(order.valid?).to be(false)
        expect(order.errors).not_to be_nil
      end

      it 'is valid when store_credit_amount is 0' do
        order.instance_variable_set(:@store_credit_amount, 0)
        allow(order).to receive_messages(item_total: 50)
        expect(order.valid?).to be(true)
        expect(order.errors.count).to be(0)
      end
    end

      describe "when item total is greater than limit" do
        before { reset_spree_preferences { |config| config.use_store_credit_minimum = 10 } }

        it "should be valid when item total is greater than limit" do
          expect(order.valid?).to be_truthy
          expect(order.errors.count).to eq(0)
        end

      it 'is valid when item total is greater than limit' do
        expect(order.valid?).to be(true)
        expect(order.errors.count).to be(0)
      end
    end
  end
end
