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

      verify_store_credits '$3.00'
    end

    scenario 'accumulates my store credits' do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      user = Spree.user_class.where(email: email).first
      expect(user.store_credits.count).to be(0)

      goto_and_process_checkout
      place_order!

      expect(current_path).to eq spree.order_path(Spree::Order.last)
      expect(Spree::Order.count).to be(1)

      verify_store_credits '$3.00'

      expect(user.store_credits.count).to be(1)
      expect(user.store_credits[0].amount.to_f).to be(3.0)

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
  end
end
