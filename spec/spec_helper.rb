# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require 'simplecov' if ENV["COVERAGE"]

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'rspec/active_model/mocks'
require 'factory_girl'
require 'spree/testing_support/url_helpers'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f }

# Requires factories defined in spree_core

require 'spree/testing_support/factories'

# include local factories
Dir["#{File.dirname(__FILE__)}/factories/**/*.rb"].each { |f| require File.expand_path(f)}

require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/order_walkthrough'

require 'ffaker'

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
options = {
  js_errors: false,
  timeout: 240,
  phantomjs_logger: StringIO.new,
  logger: nil,
  phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes']
}

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end
Capybara.default_wait_time = 10

RSpec.configure do |config|
  config.color = true
  config.mock_with :rspec

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false
 
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:each, type: :feature) do |example| 
    missing_translations = page.body.scan(/translation missing: #{I18n.locale}\.(.*?)[\s<\"&]/)
    if missing_translations.any?
      #binding.pry
      puts "Found missing translations: #{missing_translations.inspect}"
      puts "In spec: #{example.location}"
    end
    if example.exception
      page.save_screenshot("tmp/capybara/screenshots/#{example.metadata[:description]}.png", full: true)
      save_and_open_page
    end
  end

  config.include FactoryGirl::Syntax::Methods
  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::ControllerRequests, :type => :controller
  config.include Rack::Test::Methods, :type => :feature
  config.include Capybara::DSL

  config.fail_fast = ENV['FAIL_FAST'] == 'true' || false
end
