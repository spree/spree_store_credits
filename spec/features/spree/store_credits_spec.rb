require 'spec_helper'

RSpec.describe 'Promotion for Store Credits', type: :feature, inaccessible: true do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:credit_card_payment_method) }
  let!(:zone) { create(:zone) }

  context "#new user" do
    let(:address) { create(:address, :state => Spree::State.first) }
    let(:promotion) { create(:promotion_for_store_credits, path: 'orders/populate', created_at: 2.days.ago) }

    before do
      promotion
      shipping_method.calculator.set_preference(:amount, 10)
    end

    it "should give me a store credit when I register", :js => true do
      email = 'paul@gmail.com'

      expect{setup_new_user_and_sign_up(email)}.to change(Spree::StoreCredit, :count).by(1)
      new_user = Spree.user_class.find_by_email email
      expect(new_user.store_credits.size).to eq(1)
    end

    it "should not allow the user to apply the store credit if minimum order amount is not reached", :js => true do
      reset_spree_preferences do |config|
       config.use_store_credit_minimum = 100
      end
      email = 'george@gmail.com'
      expect{setup_new_user_and_sign_up(email)}.to change(Spree::StoreCredit, :count).by(1)
      
      # regression fix double giving store credits
      expect(Spree.user_class.find_by(email: email).store_credits(true).count).to eq(1)
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      expect(page).to have_content("You have $1,234.56 of store credits")
      fill_in "order_store_credit_amount", :with => "50"

      click_button "Save and Continue"
      expect(page).to have_content("Order's item total is less than the minimum allowed ($100.00) to use store credit")

      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 1
      end
      
      fill_in_credit_card
      expect(page).to have_content("You have $1,234.56 of store credits")
      fill_in "order_store_credit_amount", :with => "19.99"

      click_button "Save and Continue"
      # Store credits MAXIMUM => item_total - 0.01 in order to be valid ex : paypal orders
      expect(page).to have_content("-$19.99")
      expect(page).to have_content("Your order has been processed successfully")
      expect(Spree::Order.count).to eq(1)
      expect(Spree::Order.last.total).to eq(0)
      expect(Spree::Order.last.item_total).to eq(19.99)
      expect(Spree::Order.last.adjustments.last.amount).to eq(-19.99)
      

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $1,214.57")
    end

    it "should allow if not using store credit and minimum order is not reached", :js => true do
      reset_spree_preferences do |config|
       config.use_store_credit_minimum = 100
      end

      email = 'patrick@gmail.com'
      expect{setup_new_user_and_sign_up(email)}.to change(Spree::StoreCredit, :count).by(1)
      user = Spree.user_class.where(email: email).first

      expect(user.store_credits(true).count).to eq(1)

      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card
      fill_in "order_store_credit_amount", :with => "0"

      click_button "Save and Continue"

      click_button Spree.t(:place_order)

      expect(page).to have_content(Spree.t(:order_processed_successfully))
      expect(Spree::Order.count).to eq(1) # 1 Purchased + 1 new empty cart order
      expect(Spree::Order.last.total).to eq(19.99)
      expect(Spree::Order.last.item_total).to eq(19.99)
      expect(Spree::Order.last.adjustments.count).to eq(0)

      # store credits should be unchanged
      visit spree.account_path
      expect(page).to have_content("Current store credit: $1,234.56")
    end

    it "should allow using store credit if minimum order amount is reached", :js => true do
      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 10
      end
      email = 'sam@gmail.com'
      expect{setup_new_user_and_sign_up(email)}.to change(Spree::StoreCredit, :count).by(1)
      expect(Spree.user_class.find_by_email(email).store_credits(true).count).to eq(1)

      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      fill_in "order_store_credit_amount", :with => "10"
      click_button "Save and Continue"
      
      expect(page).to have_content("-$10.00")
      expect(Spree::Order.last.total).to eq(9.99)
      expect(Spree::Order.last.item_total).to eq(19.99)
      expect(Spree::Order.last.adjustments.last.amount).to eq(-10.00)
      click_on "Place Order"

      expect(page).to have_content("Your order has been processed successfully")
      expect(Spree::Order.count).to eq(1)
      expect(Spree::Payment.count).to eq(1)
      expect(Spree::Order.last.total).to eq(9.99)
      expect(Spree::Order.last.item_total).to eq(19.99)
      expect(Spree::Order.last.adjustments.last.amount).to eq(-10.00)  
      
      expect(Spree::Payment.last.amount.to_f).to eq Spree::Order.last.total.to_f
      expect(Spree::Order.last.total).to eq(9.99)
      expect(Spree::Order.last.item_total).to eq(19.99)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $1,224.56")
    end

    it "should allow using store credit as partial payment if minimum order amount is reached", :js => true do
      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 10
      end
      email = 'sam@gmail.com'
      expect{setup_new_user_and_sign_up(email)}.to change(Spree::StoreCredit, :count).by(1)
      user = Spree.user_class.find_by_email(email)
      expect(user.store_credits.count).to eq(1)

      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      fill_in "order_store_credit_amount", :with => "3"
      click_button "Save and Continue"

      expect(page).to have_content("-$3.00")
      expect(Spree::Order.last.total).to eq(16.99)
      expect(Spree::Order.last.item_total).to eq(19.99)
      expect(Spree::Order.last.adjustments.last.amount).to eq(-3.00)
      click_on "Place Order"
      expect(page).to have_content("Your order has been processed successfully")
      expect(Spree::Order.count).to eq(1)
      expect(Spree::Payment.count).to eq(1)
      
      expect(Spree::Payment.last.amount.to_f).to eq Spree::Order.last.total.to_f
      expect(Spree::Order.last.total).to eq(16.99)
      expect(Spree::Order.last.item_total).to eq(19.99)
      expect(Spree::Order.last.adjustments.last.amount).to eq(-3.00)
      expect(user.store_credits.count).to eq(1)

      Spree::Payment.last.complete
      
      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $1,231.56")

      bag = create(:product, name: "RoR Bag", price: 59.99)
      visit spree.root_path
      click_link bag.name
      expect(page).to have_content(Spree.t(:add_to_cart))
      click_button "add-to-cart-button"

      click_button Spree.t(:checkout)
      sleep 1
      
      fill_in_address
      click_on Spree.t(:save_and_continue)
      sleep 2
      click_on Spree.t(:save_and_continue)
      
      fill_in "order_store_credit_amount", :with => "3"

      click_on Spree.t(:save_and_continue)


      click_button Spree.t(:place_order)
      
      expect(user.store_credits.count).to eq(2)

      puts "Spree::Payment.all: #{Spree::Payment.all.inspect}"
      
      expect(Spree::Order.last.adjustments.last.amount).to eq(-3.00)
      expect(Spree::Order.last.total).to eq(56.99)
      expect(Spree::Order.last.item_total).to eq(59.99)
      expect(Spree::Payment.last.amount.to_f).to eq Spree::Order.last.total.to_f
      
      expect(Spree::Order.count).to eq(2) 

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("#{Spree.t(:current_store_credit)}: $9.00")
    end

    it "should allow even when admin is giving store credits", :js => true do
      sign_in_as! user = FactoryGirl.create(:admin_user)
      visit spree.new_admin_user_store_credit_path(user)
      fill_in "Amount", :with => 10
      fill_in "Reason", :with => "Gift"

      click_button "Create"

      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 10
      end

      visit spree.product_path(mug)

      click_button "Add To Cart"
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      fill_in "order_store_credit_amount", :with => "10"

      click_button "Save and Continue"
      expect(page).to have_content("-$10.00")
      click_on "Place Order"
      expect(page).to have_content("Your order has been processed successfully")

      # store credits should be consumed
      visit spree.account_path

      expect(page).not_to have_content('Current store credit: $10.00')
      expect(Spree::Order.count).to eq(1) 
    end

    after(:each) { reset_spree_preferences }
  end
end