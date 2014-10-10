RSpec.feature 'Promotion for Store Credits', :js, :inaccessible do

  given!(:country)         { create(:country, states_required: true) }
  given!(:state)           { create(:state, country: country) }
  given!(:shipping_method) { create(:shipping_method) }
  given!(:stock_location)  { create(:stock_location) }
  given!(:mug)             { create(:product, name: 'RoR Mug') }
  given!(:payment_method)  { create(:credit_card_payment_method) }
  given!(:zone)            { create(:zone) }

  context 'when new user' do
    given!(:address)   { create(:address, state: Spree::State.first) }
    given!(:promotion) { create(:promotion_for_store_credits, path: 'orders/populate', created_at: 2.days.ago) }

    background do
      promotion
      shipping_method.calculator.set_preference(:amount, 10)
    end

    after { reset_spree_preferences }

    scenario 'gives me a store credit when I register' do
      email = 'paul@gmail.com'
      expect {
        setup_new_user_and_sign_up(email)
      }.to change(Spree::StoreCredit, :count).by(1)

      new_user = Spree.user_class.find_by_email email
      expect(new_user.store_credits.size).to be(1)
    end

    scenario 'does not allow the user to apply the store credit if minimum order amount is not reached' do
      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 100
      end

      email = 'george@gmail.com'
      expect {
        setup_new_user_and_sign_up(email)
      }.to change(Spree::StoreCredit, :count).by(1)

      # regression fix double giving store credits
      expect(Spree.user_class.find_by(email: email).store_credits(true).count).to be(1)

      click_button Spree.t(:checkout)
      fill_in_address
      click_button Spree.t(:save_and_continue)
      click_button Spree.t(:save_and_continue)
      fill_in_credit_card

      expect(page).to have_content 'You have $1,234.56 of store credits'
      fill_in 'order_store_credit_amount', with: '50'

      click_button "Save and Continue"
      expect(page).to have_content("Order's item total is less than the minimum allowed ($100.00) to use store credit")

      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 1
      end

      fill_in_credit_card
      expect(page).to have_content 'You have $1,234.56 of store credits'
      fill_in 'order_store_credit_amount', with: '19.99'

      click_button Spree.t(:save_and_continue)

      # Store credits MAXIMUM => item_total - 0.01 in order to be valid ex : paypal orders
      expect(page).to have_content '-$19.99'
      expect(page).to have_content 'Your order has been processed successfully'
      expect(Spree::Order.count).to be(1)
      expect(Spree::Order.last.total.to_f).to be(0.0)
      expect(Spree::Order.last.item_total.to_f).to be(19.99)
      expect(Spree::Order.last.adjustments.last.amount.to_f).to be(-19.99)

      verify_store_credits '$1,214.57'
    end

    scenario 'allows if not using store credit and minimum order is not reached' do
      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 100
      end

      email = 'patrick@gmail.com'
      expect {
        setup_new_user_and_sign_up(email)
      }.to change(Spree::StoreCredit, :count).by(1)

      user = Spree.user_class.where(email: email).first
      expect(user.store_credits(true).count).to be(1)

      goto_and_process_checkout '0'
      place_order!

      expect(Spree::Order.count).to be(1) # 1 Purchased + 1 new empty cart order
      expect(Spree::Order.last.total.to_f).to be(19.99)
      expect(Spree::Order.last.item_total.to_f).to be(19.99)
      expect(Spree::Order.last.adjustments.count).to be(0)

      verify_store_credits '$1,234.56'
    end

      # store credits should be unchanged
      visit spree.account_path
      page.should have_content("Current store credit: $1,234.56")
    end

      email = 'sam@gmail.com'
      expect {
        setup_new_user_and_sign_up(email)
      }.to change(Spree::StoreCredit, :count).by(1)

      expect(Spree.user_class.find_by_email(email).store_credits(true).count).to be(1)

      goto_and_process_checkout '10'

      expect(page).to have_content '-$10.00'
      expect(Spree::Order.last.total.to_f).to be(9.99)
      expect(Spree::Order.last.item_total.to_f).to be(19.99)
      expect(Spree::Order.last.adjustments.last.amount.to_f).to be(-10.00)

      place_order!

      expect(Spree::Order.count).to be(1)
      expect(Spree::Payment.count).to be(1)
      expect(Spree::Order.last.total.to_f).to be(9.99)
      expect(Spree::Order.last.item_total.to_f).to be(19.99)
      expect(Spree::Order.last.adjustments.last.amount.to_f).to be(-10.00)
      expect(Spree::Payment.last.amount.to_f).to be(Spree::Order.last.total.to_f)
      expect(Spree::Order.last.total.to_f).to be(9.99)
      expect(Spree::Order.last.item_total.to_f).to be(19.99)

      verify_store_credits '$1,224.56'
    end

    scenario 'allows using store credit as partial payment if minimum order amount is reached' do
      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 10
      end

      email = 'sam@gmail.com'
      setup_new_user_and_sign_up(email)
      Spree.user_class.find_by_email(email).store_credits(true).count.should == 1

      click_button "Checkout"

      goto_and_process_checkout('3')

      expect(page).to have_content '-$3.00'
      expect(Spree::Order.last.total.to_f).to be(16.99)
      expect(Spree::Order.last.item_total.to_f).to be(19.99)
      expect(Spree::Order.last.adjustments.last.amount.to_f).to be(-3.00)

      page.should have_content("$-10.00")
      page.should have_content("Your order has been processed successfully")
      Spree::Order.count.should == 2 # 1 Purchased + 1 new empty cart order

      expect(Spree::Order.count).to be(1)
      expect(Spree::Payment.count).to be(1)
      expect(Spree::Payment.last.amount.to_f).to be(Spree::Order.last.total.to_f)
      expect(Spree::Order.last.total.to_f).to be(16.99)
      expect(Spree::Order.last.item_total.to_f).to be(19.99)
      expect(Spree::Order.last.adjustments.last.amount.to_f).to be(-3.00)
      expect(user.store_credits.count).to be(1)

      Spree::Payment.last.complete

      verify_store_credits '$1,231.56'

      bag = create(:product, name: 'RoR Bag', price: 59.99)

      visit spree.root_path
      click_link bag.name
      expect(page).to have_content Spree.t(:add_to_cart)
      click_button Spree.t(:add_to_cart)

      goto_and_process_checkout '3'
      place_order!

      expect(user.store_credits.count).to be(2)
      expect(Spree::Order.last.adjustments.last.amount.to_f).to be(-3.00)
      expect(Spree::Order.last.total.to_f).to be(56.99)
      expect(Spree::Order.last.item_total.to_f).to be(59.99)
      expect(Spree::Payment.last.amount.to_f).to be(Spree::Order.last.total.to_f)
      expect(Spree::Order.count).to be(2)

      verify_store_credits '$9.00'
    end

    scenario 'allows even when admin is giving store credits' do
      sign_in_as! user = create(:admin_user)
      visit spree.new_admin_user_store_credit_path(user)
      fill_in 'Amount', with: 10
      fill_in 'Reason', with: 'Gift'

      click_button 'Create'

      reset_spree_preferences do |config|
        config.use_store_credit_minimum = 10
      end

      visit spree.product_path(mug)
      click_button Spree.t(:add_to_cart)

      goto_and_process_checkout '10'
      expect(page).to have_content '-$10.00'

      place_order!

      verify_store_credits '$10.00'
      expect(Spree::Order.count).to be(1)
    end
  end
end
