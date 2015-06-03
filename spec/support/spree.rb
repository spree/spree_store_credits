require 'spree/testing_support/factories'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/capybara_ext'
require 'spree/testing_support/order_walkthrough'

RSpec.configure do |config|
  config.include Spree::TestingSupport::ControllerRequests
  config.include Spree::TestingSupport::UrlHelpers
end
