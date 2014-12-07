RSpec.describe Spree::Adjustment do
  it 'has a scope method for store credits' do
    expect(described_class).to respond_to(:store_credits)
  end
end
