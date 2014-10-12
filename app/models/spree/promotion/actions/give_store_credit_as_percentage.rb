module Spree
  class Promotion::Actions::GiveStoreCreditAsPercentage < PromotionAction
    include Spree::CalculatedAdjustments
    preference :flat_percent, :decimal, :default => 10
 
    delegate :eligible?, to: :promotion

    before_validation :ensure_action_has_calculator
    
    def perform(payload = {})
      order = payload[:order]
      user = payload[:user] || try_spree_current_user
      return if user_store_credits_already_applied?(user, order)
      amount = compute_amount(order)
      return if amount == 0
      give_store_credit(user, amount, order) if user.present?
      true
    end

    # Ensure an amount which does not exceed the sum of the order's
    # item_total and ship_total
    def compute_amount(calculable)
      amount = self.calculator.compute(calculable).to_f.abs
      [(calculable.item_total + calculable.ship_total), amount].min
    end

    private
      # Tells us if there if the specified promotion is already associated with the line item
      # regardless of whether or not its currently eligible. Useful because generally
      # you would only want a promotion action to apply to order no more than once.
      #
      # Receives an adjustment +source+ (here a PromotionAction object) and tells
      # if the order has adjustments from that already
      def user_store_credits_already_applied?(user, order)
        user.store_credits.where(reason: credit_reason(order.number)).exists?
      end

      def ensure_action_has_calculator
        return if self.calculator
        self.calculator = Calculator::FlatPercentItemTotal.new(preferred_flat_percent: preferred_flat_percent)
      end


      def give_store_credit(user, amount, order)
        user.store_credits.create(amount: amount, remaining_amount: amount,
                                  reason: credit_reason(order.number))
      end

      def credit_reason(number)
        "#{Spree.t(:promotion)} #{promotion.name} for order #{number}"
      end

  end
end
