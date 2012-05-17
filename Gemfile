source 'http://rubygems.org'

group :test do
  gem 'ffaker'
end

group :test, :development do
  gem 'spree', :git => "git://github.com/spree/spree.git", :branch => "1-0-stable"
end

if RUBY_VERSION < "1.9"
  gem "ruby-debug"
else
  gem "ruby-debug19"
end

gemspec
