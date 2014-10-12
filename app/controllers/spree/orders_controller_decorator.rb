module Spree
  OrdersController.class_eval do

    after_action :fire_visited_path, only: :populate
    
    def fire_visited_path
      current_path = URI.parse(request.original_url).path
      PromotionHandler::Page.new(current_order, current_path, try_spree_current_user).activate
    end

    def show
      @order = Order.find_by_number!(params[:id])
      PromotionHandler::Page.new(@order, 'orders', try_spree_current_user).execute
    end

  end
end