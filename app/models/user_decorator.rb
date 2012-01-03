User.class_eval do
  has_many :store_credits

  def has_store_credit?
    store_credits_total > 0
  end

  def store_credits_total
    if store_credits.any? and !Spree::Config[:store_credit_expire_days].blank?
      result = store_credits.find(:all, :select => 'max(created_at) recent', :conditions => 'remaining_amount > 0')
      max_date = result[0]['recent']
      if max_date and (Spree::Config[:store_credit_expire_days].to_i).days.ago.beginning_of_day > max_date
        0
      else
        store_credits.sum(:remaining_amount)
      end
    else
      store_credits.sum(:remaining_amount)
    end
  end

  def store_credits_expiration
    if store_credits.any? and !Spree::Config[:store_credit_expire_days].blank?
      result = store_credits.find(:all, :select => 'max(created_at) recent', :conditions => 'remaining_amount > 0')
      result[0]['recent'] + Spree::Config[:store_credit_expire_days].days
    end
  end
end
