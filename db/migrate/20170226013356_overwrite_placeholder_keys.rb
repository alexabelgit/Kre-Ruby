class OverwritePlaceholderKeys < ActiveRecord::Migration[5.0]
  def change

    Store.all.each do |store|

      new_val = store.settings(:reviews).comment_mail_body.gsub('[product]', '[product_link]').gsub('[store_url]', '[store_link]')
      store.settings(:reviews).update_attributes(comment_mail_body: new_val)

      new_val = store.settings(:questions).comment_mail_body.gsub('[product]', '[product_link]').gsub('[store_url]', '[store_link]')
      store.settings(:questions).update_attributes(comment_mail_body: new_val)

      new_val = store.settings(:reviews).review_request_mail_body.gsub('[store_url]', '[store_link]')
      store.settings(:reviews).update_attributes(review_request_mail_body: new_val)

    end

  end
end
