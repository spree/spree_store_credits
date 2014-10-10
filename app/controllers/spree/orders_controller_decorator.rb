Spree::OrdersController.class_eval do

  after_action :fire_visited_path, only: :populate

  def fire_visited_path
    current_path = URI.parse(request.original_url).path
    Spree::PromotionHandler::Page.new(current_order, current_path, try_spree_current_user).activate
  end
end