RSpec.describe Spree::Admin::StoreCreditsController, type: :controller do
  stub_authorization!

  before do
    user = create(:admin_user)
    allow(controller).to receive_messages(spree_current_user: user)
  end

  context '#index' do
    context 'with store credits' do
      let!(:store_credits) { 3.times.map { create(:store_credit) } }

      it 'displays the index page' do
        spree_get :index
        expect(response.status).to be(200)
        expect(response).to render_template(:index)
        assigned_credits = assigns(:collection)
        store_credits.each do |credit|
          expect(assigned_credits).to include(credit)
        end
      end
    end

    context 'without store credits' do
      it 'displays an empty page' do
        spree_get :index
        expect(response.status).to be(200)
        expect(response).to render_template(:index)
        expect(assigns(:collection)).to be_empty
      end
    end
  end

  context '#new' do
    it 'renders the correct template' do
      spree_get :new
      expect(response.status).to be(200)
      expect(response).to render_template(:new)
    end
  end

  context '#create' do
    let(:user) { create(:user) }
    let(:reason) { SecureRandom.hex(5) }
    let(:amount) { BigDecimal.new(rand * 100, 2).to_f }

    it 'creates a store credit for the user when arguments are provided' do
      expect {
        spree_post :create, store_credit: { amount: amount, reason: reason, user_id: user.id }
        expect(response).to redirect_to(spree.admin_store_credits_path)
      }.to change(Spree::StoreCredit, :count).by(1)
      user.reload
      store_credit = user.store_credits.first
      expect(store_credit).to_not be_nil
      expect(store_credit.user).to eq(user)
      expect(store_credit.reason).to eq(reason)
      expect(store_credit.amount).to eq(amount)
      expect(store_credit.remaining_amount).to eq(amount)
    end
  end

  context '#edit' do
    let(:new_store_credit) { create(:store_credit, amount: 40.0, remaining_amount: 40.0) }
    let(:used_store_credit) { create(:store_credit, amount: 40.0, remaining_amount: 20.0) }

    it 'renders the correct template for a new store credit' do
      spree_get :edit, id: new_store_credit
      expect(response.status).to be(200)
      expect(response).to render_template(:edit)
    end

    it 'redirects to spree.admin_store_credits_path for a used store credit' do
      spree_get :edit, id: used_store_credit
      expect(response).to redirect_to(spree.admin_store_credits_path)
      expect(flash[:error]).to eq('Cannot be edited because it has been used')
    end
  end

  context '#update' do
    let(:new_store_credit) { create(:store_credit, amount: 40.0, remaining_amount: 40.0) }
    let(:used_store_credit) { create(:store_credit, amount: 40.0, remaining_amount: 20.0) }

    it 'updates the value and redirect for a new store credit' do
      new_reason = SecureRandom.hex(5)
      spree_put :update, id: new_store_credit, store_credit: { amount: new_store_credit.amount,
                                                               remaining_amount: new_store_credit.remaining_amount,
                                                               user_id: new_store_credit.user,
                                                               reason: new_reason }
      new_store_credit.reload
      expect(new_store_credit.reason).to eq(new_reason)
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to(spree.admin_store_credits_path)
    end

    it 'redirects to spree.admin_store_credits_path for a used store credit' do
      old_reason = used_store_credit.reason
      new_reason = SecureRandom.hex(5)
      spree_put :update, id: used_store_credit, store_credit: { amount: used_store_credit.amount,
                                                                remaining_amount: used_store_credit.remaining_amount,
                                                                user_id: used_store_credit.user,
                                                                reason: new_reason }
      expect(response).to redirect_to(spree.admin_store_credits_path)
      expect(flash[:error]).to eq('Cannot be edited because it has been used')
      used_store_credit.reload
      expect(used_store_credit.reason).to eq(old_reason)
    end
  end

  context '#destroy' do
    let!(:store_credit) { create(:store_credit) }
    it 'destroys the store credit' do
      expect {
        spree_delete :destroy, id: store_credit.id
        expect(response).to redirect_to(spree.admin_store_credits_path)
      }.to change(Spree::StoreCredit, :count).by(-1)
    end
  end
end
