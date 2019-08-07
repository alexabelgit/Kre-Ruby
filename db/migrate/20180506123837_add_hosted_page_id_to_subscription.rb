class AddHostedPageIdToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :hosted_page_id, :text, index: true
  end
end
