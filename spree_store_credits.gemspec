# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY

  s.name        = 'spree_store_credits'
  s.version     = '1.1.2'
  s.authors     = ["Roman Smirnov", "Brian Quinn"]
  s.email       = 'roman@railsdog.com'
  s.homepage    = 'http://github.com/spree/spree-store-credits'
  s.summary     = 'Provides store credits for a Spree store.'
  s.description = 'Provides store credits for a Spree store.'
  s.required_ruby_version = '>= 2.1.0'
  s.rubygems_version      = '2.2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  spree_version = '~> 2.4.0'
  s.add_dependency 'spree_api', spree_version
  s.add_dependency 'spree_core', spree_version
  s.add_dependency 'spree_frontend', spree_version
  s.add_dependency 'spree_backend', spree_version
  s.add_development_dependency 'spree_sample', spree_version

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails', "~> 3.1.0"
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'launchy'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
end
