require 'spree_core'
require 'spree_promo'
require 'spree_store_credits_hooks'

module SpreeStoreCredits
  class Engine < Rails::Engine
    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env == "production" ? require(c) : load(c)
      end
      AppConfiguration.class_eval do
        preference :use_store_credit_minimum, :float, :default => 30.0
      end
    end

    config.to_prepare &method(:activate).to_proc
    config.autoload_paths += %W(#{config.root}/lib)

    initializer "spree.promo.register.promotions.actions" do |app|
      app.config.spree.promotions.actions.concat([Promotion::Actions::GiveStoreCredit])
    end
  end
end

