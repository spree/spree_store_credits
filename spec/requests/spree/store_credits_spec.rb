require 'spec_helper'

module Spree
  describe "Promotion for Store Credits" do

    context "#new user" do
      before do
        PAYMENT_STATES = Spree::Payment.state_machine.states.keys unless defined? PAYMENT_STATES
        SHIPMENT_STATES = Spree::Shipment.state_machine.states.keys unless defined? SHIPMENT_STATES
        ORDER_STATES = Spree::Order.state_machine.states.keys unless defined? ORDER_STATES
        FactoryGirl.create(:shipping_method, :zone => Spree::Zone.find_by_name('North America'))
        FactoryGirl.create(:payment_method, :environment => 'test')
        @product = FactoryGirl.create(:product, :name => "RoR Mug")
      end
      let!(:address) { FactoryGirl.create(:address, :state => Spree::State.first) }

      it "should give me a store credit when I register" do
        FactoryGirl.create(:promotion_for_store_credits, :event_name => "spree.user.signup")
        visit "/signup"

        fill_in "Email", :with => "paul@gmail.com"
        fill_in "Password", :with => "qwerty"
        fill_in "Password Confirmation", :with => "qwerty"
        click_button "Create"

        new_user = User.find_by_email "paul@gmail.com"
        new_user.store_credits.size.should == 1
      end

      it "should not allow if minimum order is not reached", :js => true do
        reset_spree_preferences do |config|
         config.use_store_credit_minimum = 100
        end
        FactoryGirl.create(:promotion_for_store_credits, :event_name => "spree.user.signup")
        visit "/signup"

        fill_in "Email", :with => "george@gmail.com"
        fill_in "Password", :with => "qwerty"
        fill_in "Password Confirmation", :with => "qwerty"
        click_button "Create"

        visit spree.product_path(@product)
        click_button "Add To Cart"

        # regression fix double giving store credits
        User.find_by_email("george@gmail.com").store_credits(true).count.should == 1
        click_button "Checkout"

        str_addr = "bill_address"
        select "United States", :from => "order_#{str_addr}_attributes_country_id"
        ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
          fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
        end

        select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
        check "order_use_billing"
        click_button "Save and Continue"
        click_button "Save and Continue"
        page.should have_content("You have $1,234.56 of store credits")
        fill_in "order_store_credit_amount", :with => "50"

        click_button "Save and Continue"
        page.should have_content("Order's item total is less than the minimum allowed ($100.00) to use store credit")

        reset_spree_preferences do |config|
          config.use_store_credit_minimum = 1
        end
        click_button "Save and Continue"
        # Store credits MAXIMUM => item_total - 0.01 in order to be valid ex : paypal orders
        page.should have_content("$-19.98")
        page.should have_content("Your order has been processed successfully")
        Spree::Order.count.should == 1
      end

      it "should allow if not using store credit and minimum order is not reached", :js => true do
        reset_spree_preferences do |config|
         config.use_store_credit_minimum = 100
        end

        FactoryGirl.create(:promotion_for_store_credits, :event_name => "spree.user.signup")
        visit "/signup"

        fill_in "Email", :with => "patrick@gmail.com"
        fill_in "Password", :with => "qwerty"
        fill_in "Password Confirmation", :with => "qwerty"
        click_button "Create"

        User.find_by_email("patrick@gmail.com").store_credits(true).count.should == 1

        visit spree.product_path(@product)

        click_button "Add To Cart"
        click_button "Checkout"

        str_addr = "bill_address"
        select "United States", :from => "order_#{str_addr}_attributes_country_id"
        ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
          fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
        end

        select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
        check "order_use_billing"
        click_button "Save and Continue"
        click_button "Save and Continue"
        fill_in "order_store_credit_amount", :with => "0"

        click_button "Save and Continue"
        page.should have_content("Your order has been processed successfully")
        Spree::Order.count.should == 1
      end

      it "should allow if using store credit and minimum order is not reached", :js => true do
        reset_spree_preferences do |config|
          config.use_store_credit_minimum = 10
        end
        FactoryGirl.create(:promotion_for_store_credits, :event_name => "spree.user.signup")
        visit "/signup"
        fill_in "Email", :with => "sam@gmail.com"
        fill_in "Password", :with => "qwerty"
        fill_in "Password Confirmation", :with => "qwerty"
        click_button "Create"

        User.find_by_email("sam@gmail.com").store_credits(true).count.should == 1

        visit spree.product_path(@product)

        click_button "Add To Cart"
        click_button "Checkout"

        str_addr = "bill_address"
        select "United States", :from => "order_#{str_addr}_attributes_country_id"
        ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
          fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
        end

        select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
        check "order_use_billing"
        click_button "Save and Continue"
        click_button "Save and Continue"

        fill_in "order_store_credit_amount", :with => "10"
        click_button "Save and Continue"

        page.should have_content("$-10.00")
        page.should have_content("Your order has been processed successfully")
        Spree::Order.count.should == 1
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

        visit spree.product_path(@product)

        click_button "Add To Cart"
        click_button "Checkout"

        str_addr = "bill_address"
        select "United States", :from => "order_#{str_addr}_attributes_country_id"
        ['firstname', 'lastname', 'address1', 'city', 'zipcode', 'phone'].each do |field|
          fill_in "order_#{str_addr}_attributes_#{field}", :with => "#{address.send(field)}"
        end

        select "#{address.state.name}", :from => "order_#{str_addr}_attributes_state_id"
        check "order_use_billing"
        click_button "Save and Continue"
        click_button "Save and Continue"
        fill_in "order_store_credit_amount", :with => "10"

        click_button "Save and Continue"
        page.should have_content("$-10.00")
        page.should have_content("Your order has been processed successfully")
        Spree::Order.count.should == 1
      end

      after(:each) { reset_spree_preferences }
    end
  end
end
