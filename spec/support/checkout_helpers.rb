def add_mug_to_cart
  visit spree.root_path
  click_link mug.name
  expect(page).to have_content(Spree.t(:add_to_cart))
  click_button "add-to-cart-button"
end

def setup_new_user_and_sign_up(email)
    visit spree.signup_path

    fill_in "Email", with: email
    fill_in "Password", with: "qwerty"
    fill_in "Password Confirmation", with: "qwerty"
    click_button "Create"
    add_mug_to_cart
end

def fill_in_address
  address = "order_bill_address_attributes"
  fill_in "#{address}_firstname", :with => "Ryan"
  fill_in "#{address}_lastname", :with => "Bigg"
  fill_in "#{address}_address1", :with => "143 Swan Street"
  fill_in "#{address}_city", :with => "Richmond"
  select "United States of America", :from => "#{address}_country_id"
  select "Alabama", :from => "#{address}_state_id"
  fill_in "#{address}_zipcode", :with => "12345"
  fill_in "#{address}_phone", :with => "(555) 555-5555"
end

def fill_in_credit_card
  fill_in "card_number", with: '4111111111111111'
  fill_in "card_expiry", with: '01 / 20'
  fill_in "card_code",   with: '1'
end