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

    before do
      shipping_method.calculator.set_preference(:amount, 10)
    end

    it "should give me a store credit when I register", :js => true do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.find_by_email email
      expect(new_user.store_credits.size).to eq(1)
    end

    it "should not allow the user to apply the store credit if minimum order amount is not reached", :js => true do
      reset_spree_preferences do |config|
       config.use_store_credit_minimum = 100
      end
      email = 'george@gmail.com'
      setup_new_user_and_sign_up(email)

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

      click_button "Save and Continue"
      # Store credits MAXIMUM => item_total - 0.01 in order to be valid ex : paypal orders
      expect(page).to have_content("-$19.99")
      expect(page).to have_content("Your order has been processed successfully")
      expect(Spree::Order.count).to eq(1) 

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $1,214.57")
    end

    it "should allow if not using store credit and minimum order is not reached", :js => true do
      reset_spree_preferences do |config|
       config.use_store_credit_minimum = 100
      end

      email = 'patrick@gmail.com'
      setup_new_user_and_sign_up(email)
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

      # store credits should be unchanged
      visit spree.account_path
      expect(page).to have_content("Current store credit: $1,234.56")
    end

    it "should allow using store credit if minimum order amount is reached", :js => true do
      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 10
      end
      email = 'sam@gmail.com'
      setup_new_user_and_sign_up(email)
      expect(Spree.user_class.find_by_email(email).store_credits(true).count).to eq(1)

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
      expect(Spree::Order.count).to eq(1)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $1,224.56")
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