require 'spec_helper'

RSpec.describe Spree::Promotion::Actions::GiveStoreCredit, :type => :model do
  let(:promotion) { create(:promotion) }
  subject { 
    a = Spree::Promotion::Actions::GiveStoreCredit.new
    a.promotion = promotion
    a.preferred_amount = 20.0
    a
  }

  context '#perform' do
    it 'passes the argument to lookup user, and passes a not nil return value to give_store_credit' do
      options_double = double
      user_double = double

      expect(subject).to receive(:lookup_user).with(options_double).and_return(user_double)
      expect(subject).to receive(:give_store_credit).with(user_double)
      subject.perform(options_double)
    end

    it 'passes the argument to lookup user, and does not give a store credit if no user is found' do
      options_double = double
      
      expect(subject).to receive(:lookup_user).with(options_double).and_return(nil)
      expect(subject).to_not receive(:give_store_credit)
      subject.perform(options_double)
    end
  end

  context '#lookup_user' do
    it 'pulls the user from the options hash' do
      user_double = double
      options = { user: user_double }
      expect(subject.lookup_user(options)).to eq(user_double)
    end
  end

  context '#give_store_credit' do
    let!(:user) { create(:user) }

    it 'adds a store credit with the specified amount and reason to the user' do
      expect {
        subject.give_store_credit(user)
      }.to change(Spree::StoreCredit, :count).by(1)
      user.reload
      expect(user.store_credits.size).to eq(1)
      last_credit = user.store_credits.first
      expect(last_credit).to_not be_nil
      expect(last_credit.amount).to eq(subject.preferred_amount)
      expect(last_credit.reason).to eq(subject.credit_reason)
      expect(last_credit.remaining_amount).to eq(last_credit.amount)
    end
  end

end