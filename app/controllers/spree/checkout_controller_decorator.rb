module Spree
  CheckoutController.class_eval do
    before_filter :remove_payments_attributes_if_total_is_zero

    [:store_credit_amount, :remove_store_credits].each do |attrib|
      Spree::PermittedAttributes.checkout_attributes << attrib unless Spree::PermittedAttributes.checkout_attributes.include?(attrib)
    end

    def update
      if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
        @order.temporary_address = !params[:save_user_address]
        unless @order.next
          flash[:error] = @order.errors.full_messages.join("\n")
          puts "ERROR: #{@order.errors.inspect}"
          redirect_to checkout_state_path(@order.state) and return
        end

        if @order.completed?
          @current_order = nil
          flash.notice = Spree.t(:order_processed_successfully)
          flash['order_completed'] = true
          redirect_to completion_route
        else
          redirect_to checkout_state_path(@order.state)
        end
      else
        render :edit
      end
    end

    private
    def remove_payments_attributes_if_total_is_zero
      load_order_with_lock

      return unless params[:order] && params[:order][:store_credit_amount]
      parsed_credit = Spree::Price.new
      parsed_credit.price = params[:order][:store_credit_amount]
      store_credit_amount = [parsed_credit.price, spree_current_user.store_credits_total].min
      if store_credit_amount >= (current_order.total + @order.store_credit_amount)
        params[:order].delete(:source_attributes)
        params.delete(:payment_source)
        params[:order].delete(:payments_attributes)
      end
    end
  end
end
