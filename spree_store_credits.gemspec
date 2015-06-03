lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_store_credits/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_store_credits'
  s.version     = SpreeStoreCredits.version
  s.summary     = 'Provides store credits for Spree Commerce.'
  s.description = s.summary
  s.required_ruby_version = '>= 2.1.0'

  s.rubygems_version      = '2.2.0'

  s.authors     = ['Roman Smirnov', 'Brian Quinn']
  s.email       = ['roman@railsdog.com', 'gems@spreecomerce.com']
  s.homepage    = 'http://github.com/spree-contrib/spree-store-credits'
  s.license     = 'BSD-3'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '~> 3.1.0.beta'
  s.add_dependency 'spree_api', spree_version
  s.add_dependency 'spree_core', spree_version
  s.add_dependency 'spree_frontend', spree_version
  s.add_dependency 'spree_backend', spree_version
  s.add_development_dependency 'spree_sample', spree_version

  s.add_development_dependency 'capybara', '~> 2.2.1'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.14.2'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'factory_girl_rails', '~> 4.4.1'
  s.add_development_dependency 'database_cleaner', '1.2.0'
  s.add_development_dependency 'launchy'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'selenium-webdriver', '2.41.0'
  s.add_development_dependency 'simplecov'
end
