namespace :housekeeping do
  desc 'Resets votes counter cache for Reviews'
  task reset_reviews_counter_cache: :environment do
    reviews_query = <<-SQL
                  UPDATE reviews
                  SET votes_count = (
                       SELECT COUNT(1) FROM votes
                       WHERE votes.votable_id = reviews.id AND
                             votes.votable_type = 'Review')
SQL
    Review.connection.execute reviews_query
  end

  desc 'Resets votes counter cache for Questions'
  task reset_questions_counter_cache: :environment do
    questions_query = <<-SQL
                    UPDATE questions
                    SET votes_count = (
                        SELECT COUNT(1) FROM votes
                        WHERE votes.votable_id = questions.id AND
                              votes.votable_type = 'Question')
SQL
    Question.connection.execute questions_query
  end

  desc 'Reindex all searchkik models'
  task reindex_all: :environment do
    Product.reindex
    Review.reindex
    ReviewRequest.reindex
    Question.reindex
  end

  desc 'Resets store products counter cache'
  task reset_products_counter: :environment do
    query = <<-SQL
      UPDATE stores
        SET products_count = (
          SELECT COUNT(1) FROM products
          WHERE products.store_id = stores.id
        )
SQL
    Store.connection.execute query
  end

  desc 'Parse emoji shortcodes in reviews and questions'
  task parse_emoji_shortcodes: :environment do
    Review.where("feedback LIKE ':%:'").find_each do |review|
      review.feedback = Rumoji.decode(review.feedback)
      review.save
    end

    Question.where("body LIKE ':%%'").find_each do |question|
      question.body = Rumoji.decode(question.body)
      question.save
    end
  end

  desc 'Resync product metafields for Shopify product with reviews'
  task resync_shopify_product_metafields: :environment do
    products = Product.joins(:store).merge(Store.shopify).joins(:individual_reviews)

    products.find_each do |product|
      SyncProductMetafieldsWorker.perform_async product.store_id, product.id_from_provider
    end

    products_from_groups = Product.joins(:store).merge(Store.shopify).joins(:product_group_products)

    products_from_groups.find_each do |product|
      SyncProductMetafieldsWorker.perform_async product.store_id, product.id_from_provider
    end
  end

  desc 'Disable shopify product webhooks for stores with products that have reviews'
  task disable_shopify_product_webhooks: :environment do
    products = Product.joins(:store).merge(Store.shopify).joins(:individual_reviews)
    stores = Store.where(id: products.pluck(:store_id)).includes(:setting_objects)
    stores.each { |s| s.update_settings(:global, dismiss_product_update_webhook: true) }
  end

  desc 'Enable shopify product webhooks for stores with products that have reviews'
  task enable_shopify_product_webhooks: :environment do
    products = Product.joins(:store).merge(Store.shopify).joins(:individual_reviews)
    stores = Store.where(id: products.pluck(:store_id)).includes(:setting_objects)
    stores.each { |s| s.update_settings(:global, dismiss_product_update_webhook: false) }
  end

  desc 'Migrates reviews and questions from one store to another based on SKU matches'
  task migrate_reviews_questions: :environment do
    require 'progress_bar'
    class Array
      include ProgressBar::WithProgress
    end

    if ENV['FROM'].nil? || ENV['TO'].nil?
      puts "No FROM and TO stores are specified. Correct usage: `rake migrate_reviews_questions FROM=mQ0Sw3 TO=mQ0Sw2`"
      return
    end

    store_from = Store.find ENV['FROM']
    store_to = Store.find ENV['TO']

    migration_service = Maintenance::ReviewsAndQuestionsMigrationService.new(store_from, new_store: store_to)

    not_migrated_reviews = []
    not_migrated_questions = []

    matches = Maintenance::ProductSkuMatchingService.new(store_from, store_to).matching_products

    Searchkick.callbacks(false) do
      matches.each_with_progress do |match|
        store_from_product = store_from.products.find_by id_from_provider: match.store_from_product_id
        store_to_product = store_to.products.find_by id_from_provider: match.store_to_product_id

        not_migrated_reviews += migration_service.move_reviews store_from_product, store_to_product
        not_migrated_questions += migration_service.move_questions store_from_product, store_to_product
      end
    end

    require 'fileutils'
    base_path = File.join(Rails.root, 'tmp', "#{store_from.hashid}_to_#{store_to.hashid}_migration")
    FileUtils.mkdir_p(base_path) unless File.directory?(base_path)

    File.open(File.join(base_path, 'not_migrated_reviews.txt'), "w+") { |f| f.puts(not_migrated_reviews) }
    File.open(File.join(base_path, 'not_migrated_questions.txt'), "w+") { |f| f.puts(not_migrated_questions) }
  end
end

