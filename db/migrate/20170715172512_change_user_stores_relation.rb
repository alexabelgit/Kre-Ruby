class ChangeUserStoresRelation < ActiveRecord::Migration[5.0]
  def up
    add_reference :stores, :user, index: true
    Store.reset_column_information
    # UserStore.all.each do |user_store|
    #   store = user_store.store
    #   store.user = user_store.user
    #   store.save
    # end

    change_column_null(:stores, :user_id, false)
    add_index :stores, :user_id, unique: true, name: 'index_stores_on_user_id_unique'
  end
end
