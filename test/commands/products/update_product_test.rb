require 'test_helper'
module Products
  class UpdateProductTest < ActiveSupport::TestCase
    include ActionDispatch::TestProcess

    setup do
      @store = create :store
    end

    describe 'when store manages products' do
      let(:params) { { product: @product, name: 'Product #2', url: 'https://store.com/product_2'} }

      setup do
        stub(@store).manages_products? { true }
        @product = create :product, store: @store, name: 'Product #1', url: 'https://store.com/product_1'
      end

      test 'executes successfully' do
        outcome = described_class.run params
        assert outcome.valid?
      end

      test 'updates product name or url' do
        described_class.run params
        assert_equal 'Product #2', @product.reload.name
        assert_equal 'https://store.com/product_2', @product.reload.url
      end
    end

    describe 'when store does not manage products' do
      let(:params) { { product: @product, name: 'Product #2', url: 'https://store.com/product_2'} }

      let(:custom_image) { fixture_file_upload('files/kitty.png', 'image/png') }

      setup do
        stub(@store).manages_products? { false }
        @product = create :product, store: @store, name: 'Product #1', url: 'https://store.com/product_1'
      end

      test 'cannot change product name or url manually' do
        described_class.run params
        assert_equal 'Product #1', @product.reload.name
        assert_equal 'https://store.com/product_1', @product.reload.url
      end

      test 'can suppress product' do
        suppressed_params = { product: @product, suppressed: true }
        refute @product.suppressed
        described_class.run suppressed_params
        assert @product.reload.suppressed
      end

      test 'could set custom image' do
        image_params = params.merge(overwrite_featured_image: true, featured_image: custom_image)
        assert_nil @product.featured_image.file

        outcome = described_class.run image_params

        @product.reload
        assert @product.overwrite_featured_image
        refute_nil @product.featured_image.file
      end
    end
  end
end
