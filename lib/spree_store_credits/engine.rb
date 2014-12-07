module SpreeStoreCredits
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_store_credits'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer 'spree_store_credits.register.promotion.actions', after: 'spree.promo.register.promotions.actions' do |app|
      app.config.spree.promotions.actions <<  Spree::Promotion::Actions::GiveStoreCredit
      app.config.spree.promotions.actions <<  Spree::Promotion::Actions::GiveStoreCreditAsPercentage
    end

    class << self
      def activate
        cache_klasses = %W(#{config.root}/app/**/*_decorator*.rb #{config.root}/app/overrides/*.rb)
        Dir.glob(cache_klasses) do |klass|
          Rails.configuration.cache_classes ? require(klass) : load(klass)
        end
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
