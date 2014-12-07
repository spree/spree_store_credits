RSpec.describe Spree::User, type: :model do
  it { expect(subject).to respond_to(:store_credits) }

  let(:user_with_credits) do
    user = create(:user)
    user.store_credits.create(amount: 100, remaining_amount: 100, reason: 'A')
    user.store_credits.create(amount: 60, remaining_amount: 55, reason: 'B')
    user
  end

  let(:user_without_credits) { create(:user) }

  context '.has_store_credit?' do
    it 'returns true for users with credits' do
      expect(user_with_credits.has_store_credit?).to be(true)
    end

    it 'returns false for users without credits' do
      expect(user_without_credits.has_store_credit?).to be(false)
    end
  end

  context '.store_credits_total' do
    it 'returns the total remaining amount for users store credits' do
      expect(user_with_credits.store_credits_total.to_f).to be(155.00)
    end

    it 'does not error out on users without any credits, and should return 0.00' do
      expect(user_without_credits.store_credits_total.to_f).to be(0.00)
    end
  end
end
