require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/poltergeist'

module FeatureHelpers
  def sign_in_as!(user)
    visit '/login'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'secret'
    click_button 'Login'
  end

  def add_mug_to_cart
    visit spree.root_path
    click_link mug.name
    expect(page).to have_content Spree.t(:add_to_cart)
    click_button 'add-to-cart-button'
  end

  def setup_new_user_and_sign_up(email)
    visit spree.signup_path
    fill_in 'Email', with: email
    fill_in 'Password', with: 'qwerty'
    fill_in 'Password Confirmation', with: 'qwerty'
    click_button 'Create'
    add_mug_to_cart
  end

  def process_new_user
    email = 'paul@gmail.com'
    setup_new_user_and_sign_up(email)
    user = Spree.user_class.where(email: email).first
    expect(user.store_credits.count).to be(0)
  end

  def fill_in_address
    address = 'order_bill_address_attributes'
    fill_in "#{address}_firstname", with: 'Ryan'
    fill_in "#{address}_lastname", with: 'Bigg'
    fill_in "#{address}_address1", with: '143 Swan Street'
    fill_in "#{address}_city", with: 'Richmond'
    select 'United States of America', from: "#{address}_country_id"
    select 'Alabama', from: "#{address}_state_id"
    fill_in "#{address}_zipcode", with: '12345'
    fill_in "#{address}_phone", with: '(555) 555-5555'
  end

  def fill_in_credit_card
    fill_in 'card_number', with: '4111111111111111'
    fill_in 'card_expiry', with: '01 / 20'
    fill_in 'card_code',   with: '1'
  end

  def goto_and_process_checkout(credit_amount = nil)
    click_button Spree.t(:checkout)
    fill_in_address
    click_button Spree.t(:save_and_continue)
    click_button Spree.t(:save_and_continue)
    fill_in_credit_card if page.has_selector?('#card_number')
    fill_in 'order_store_credit_amount', with: credit_amount if credit_amount
    click_button Spree.t(:save_and_continue)
  end

  def place_order!
    click_button Spree.t(:place_order)
    expect(page).to have_content Spree.t(:order_processed_successfully)
  end

  def verify_store_credits(dollar)
    visit spree.account_path
    expect(current_path).to eq spree.account_path
    expect(page).to have_text "Current store credit: #{dollar}"
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature

  Capybara.javascript_driver = :poltergeist
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new app, timeout: 30
  end

  Capybara.default_wait_time = 15 # Default is 5.

  config.before(:each, :js) do
    if Capybara.javascript_driver == :selenium
      page.driver.browser.manage.window.maximize
    end
  end
end
