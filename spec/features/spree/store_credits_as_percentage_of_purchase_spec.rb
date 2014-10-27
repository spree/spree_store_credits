RSpec.feature 'Promotion for Store Credits as Percentage', :js, :inaccessible do

  given!(:country)         { create(:country, states_required: true) }
  given!(:state)           { create(:state, country: country) }
  given!(:shipping_method) { create(:shipping_method) }
  given!(:stock_location)  { create(:stock_location) }
  given!(:mug)             { create(:product, name: 'RoR Mug') }
  given!(:payment_method)  { create(:credit_card_payment_method) }
  given!(:zone)            { create(:zone) }

  context 'when new user' do
    given!(:address)   { create(:address, state: Spree::State.first) }
    given!(:promotion) { create(:promotion_for_store_credits_as_percentage, path: 'orders', created_at: 2.days.ago) }

    background do
      promotion
      shipping_method.calculator.set_preference(:amount, 10)
    end

    after { reset_spree_preferences }

    scenario 'gives me a store credit when I purchase an order' do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to be(0)

      goto_and_process_checkout
      place_order!

      expect(Spree::Order.count).to be(1)
      expect(new_user.store_credits.count).to be(1)

      verify_store_credits '$3.00'
    end

    scenario 'does not give me a store credit for unfinished purchases' do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to be(0)

      goto_and_process_checkout

      expect(Spree::Order.count).to be(1)
      expect(new_user.store_credits.count).to be(0)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to_not have_content 'Current store credit: $3.00'
    end

    scenario 'does not give me a store credit when I view a past order' do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to be(0)

      goto_and_process_checkout
      place_order!

      expect(current_path).to eq spree.order_path(Spree::Order.last)
      expect(Spree::Order.count).to be(1)
      expect(new_user.store_credits.count).to be(1)

      click_button Spree.t(:place_order)
      
      expect(page).to have_content("Your order has been processed successfully")
      order_path = spree.order_path(Spree::Order.last)
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      expect(Spree::Order.count).to eq(1) 
      expect(new_user.store_credits.count).to eq(1)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $3.00")

      visit order_path

      visit spree.account_path
      expect(page).to have_content("Current store credit: $3.00")      
    end 

    scenario 'accumulates my store credits' do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to eq(0)
      click_button "Checkout"

      goto_and_process_checkout
      place_order!

      expect(current_path).to eq spree.order_path(Spree::Order.last)
      expect(Spree::Order.count).to be(1)

      click_button Spree.t(:place_order)
      
      expect(page).to have_content("Your order has been processed successfully")
      order_path = spree.order_path(Spree::Order.last)
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      expect(Spree::Order.count).to eq(1) 
      expect(new_user.store_credits.count).to eq(1)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $3.00")

      bag = create(:product, name: "RoR Bag", price: 59.99)
      visit spree.root_path

      click_link bag.name
      expect(page).to have_content Spree.t(:add_to_cart)
      click_button Spree.t(:add_to_cart)

      expect(new_user.store_credits.count).to eq(1)
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      expect(page).to have_content("Use an existing card on file")
      fill_in "order_store_credit_amount", :with => "0"

      click_button "Save and Continue"

      click_button Spree.t(:place_order)
      
      expect(Spree::Order.count).to eq(2) 
      expect(new_user.store_credits.count).to eq(2)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $12.00")      
    end    

    after(:each) { reset_spree_preferences }
  end
end
