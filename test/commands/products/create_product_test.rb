require 'test_helper'

module Products
  class CreateProductTest < ActiveSupport::TestCase
    include ActionDispatch::TestProcess

    describe 'when store could not manage products' do
      test 'it fails with error' do
        store = create :store
        stub(store).manages_products? { false }

        params = { store: store, name: 'Test product'}
        outcome = described_class.run params
        refute outcome.valid?
      end
    end

    describe 'when store could manage products' do
      let(:custom_image) { fixture_file_upload('files/kitty.png', 'image/png') }

      setup do
        @store = create :store
        stub(@store).manages_products? { true }
        @params = {
          store: @store,
          name: 'Test product',
          id_from_provider: 'ABC123',
          url: 'http://product_url.com',
          suppressed: false
        }
      end

      test 'executes successfully' do
        outcome = described_class.run @params
        assert outcome.valid?
      end

      test 'creates product' do
        assert_difference -> { @store.reload.products.count }, +1 do
          described_class.run @params
        end
      end

      describe 'when overwrite featured image flag is passed' do
        test 'sets custom product image' do
          params = @params.merge overwrite_featured_image: true, featured_image: custom_image
          outcome = described_class.run params
          assert outcome.valid?
        end
      end
    end

  end
end
