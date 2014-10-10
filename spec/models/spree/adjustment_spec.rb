require 'spec_helper'

module Spree
  describe Adjustment do
    it 'has a scope method for store credits' do
      expect(Spree::Adjustment).to respond_to(:store_credits)
    end
  end
end