Spree::PromotionHandler::Page.class_eval do
  attr_reader :order, :path, :user

  def initialize(order, path, user = nil)
    @order = order
    @path  = path.gsub(/\A\//, '')
    @user  = user
  end

  def activate
    return unless promotion
    return unless promotion.eligible?(order)
    promotion.activate(order: order, user: user)
  end

  def execute
    return unless promotion
    return unless promotion.eligible?(order)
    promotion.actions.map do |action|
      action.perform(order: order, user: user)
    end
  end
end
