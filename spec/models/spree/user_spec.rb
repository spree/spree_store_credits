require 'spec_helper'

module Spree
  RSpec.describe User do
    it { expect(subject).to respond_to(:store_credits)}

    let(:user_with_credits) { 
      u = create(:user) 
      u.store_credits.create(:amount => 100, :remaining_amount => 100, :reason => "A")
      u.store_credits.create(:amount => 60, :remaining_amount => 55, :reason => "B")
      u
    }

    let(:user_without_credits) { create(:user) }

    context '#has_store_credit?' do
      it 'should return true for users with credits' do
        expect(user_with_credits.has_store_credit?).to eq(true)
      end

      it 'should return false for users without credits' do
        expect(user_without_credits.has_store_credit?).to eq(false)
      end
    end

    context '#store_credits_total' do
      it 'should return the total remaining amount for users store credits' do
        expect(user_with_credits.store_credits_total).to eq(155.00)
      end

      it 'should not error out on users without any credits, and should return 0.00' do
        expect(user_without_credits.store_credits_total).to eq(0.00)
      end
    end
  end
end
