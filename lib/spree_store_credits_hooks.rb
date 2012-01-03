class SpreeStoreCreditsHooks < Spree::ThemeSupport::HookListener

  Deface::Override.new(:virtual_path => "admin/general_settings/show",
                      :name => "converted_admin_general_settings_show_for_sc",
                       :insert_bottom => "[data-hook='preferences'], #preferences[data-hook]",
                       :text => "
<tr>
    <th scope=\"row\"><%= t(\"minimum_order_amount_for_store_credit_use\") %>:</th>
    <td><%=  Spree::Config[:use_store_credit_minimum] %></td>
</tr>
<tr>
    <th scope=\"row\"><%= t(\"number_of_days_store_credit_expires\") %>:</th>
    <td><%=  Spree::Config[:store_credit_expire_days] %></td>
</tr>
      ",
                       :disabled => false)

  Deface::Override.new(:virtual_path => "admin/general_settings/edit",
                      :name => "converted_admin_general_settings_edit_for_sc",
                       :insert_bottom => "fieldset#preferences",
                       :text => "
  <p>
	<label><%= t(\"minimum_order_amount_for_store_credit_use\") %></label>
	<%= text_field_tag('app_configuration[preferred_use_store_credit_minimum]', Spree::Config[:use_store_credit_minimum]) %>
  </p>
  <p>
	<label><%= t(\"number_of_days_store_credit_expires\") %></label>
	<%= text_field_tag('app_configuration[preferred_store_credit_expire_days]', Spree::Config[:store_credit_expire_days]) %>
  </p>
      ",
                       :disabled => false)

end