Spree::PromotionHandler::Page.class_eval do
  attr_reader :order, :path, :user

  def initialize(order, path, user = nil)
    @order = order
    @path  = path.gsub(/\A\//, '')
    @user  = user
  end

  def activate
    return unless promotion
    if promotion && promotion.eligible?(order)
      promotion.activate(order: order, user: user)
    end
  end

  def execute
    return unless promotion
    if promotion && promotion.eligible?(order)
      results = promotion.actions.map do |action|
        action.perform(order: order, user: user)
      end
      action_taken = results.include?(true)
      if action_taken
        promotion.orders << order
        promotion.save
      end

    end
  end
end