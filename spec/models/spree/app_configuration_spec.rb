RSpec.describe Spree::AppConfiguration do

  subject { described_class.new }

  it 'have the use_store_credit_minimum preference' do
    expect(subject).to respond_to(:preferred_use_store_credit_minimum)
    expect(subject).to respond_to(:preferred_use_store_credit_minimum=)
  end
end
