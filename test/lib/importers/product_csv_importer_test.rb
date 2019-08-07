require 'test_helper'

module Importers
  class ProductCsvImporterTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    describe '.valid_csv?' do
      it 'verifies that csv columns names contain necessary columns' do
        valid_csv_columns = %w[id name url image_url]
        assert described_class.valid_csv?(valid_csv_columns)

        invalid_csv_columns = %w[id name image_url video_url] # url is missing here
        refute described_class.valid_csv?(invalid_csv_columns)
      end
    end

    describe '#import' do
      let(:store) { create :store }

      before do
        create :product, store: store, id_from_provider: '3000', name: 'Orange bone',
               url: 'https://store.com/products/orange-bone'
      end
      subject { described_class.new(store) }

      let(:simple_csv) do
        [
          {
            'id' => '1000',
            'name' => 'Red bone',
            'url' => 'https://store.com/products/red-bone',
            'image_url' => 'https:://store.com/products/red-bone.jpg'
          },
          {
            'id' => '2000',
            'name' => 'Black bone',
            'url' => 'https://store.com/products/black-bone',
            'image_url' => 'https://store.com/products/black-bone.jpg'
          },
          {
            'id' => '3000',
            'name' => 'Yellow bone',
            'url' => 'https://store.com/products/yellow-bone',
            'image_url' => 'https://store.com/products/yellow-bone.jpg'
          }
        ]
      end

      # missing name and image_url
      let(:wrong_row) {
        { 'id' => '3000',
          'url' => 'https://store.come/products/blue-bone' }
      }

      let(:csv_with_wrong_rows) do
        simple_csv << wrong_row
      end

      test 'imports all valid rows from given csv' do
        unimported = subject.import simple_csv
        assert_equal 0, unimported.count
      end

      test 'creates products for rows that have id_from_provider not present in DB' do
        assert_difference 'Product.count', 2 do
          subject.import simple_csv
        end
      end

      test 'updates existing products that match id_from_provider' do
        existing_product = store.products.first
        assert_equal 'Orange bone', existing_product.name

        subject.import simple_csv

        existing_product.reload
        assert_equal 'Yellow bone', existing_product.name
        assert_equal 'https://store.com/products/yellow-bone', existing_product.url
      end

      describe 'when csv contains rows with errors' do
        test 'returns amount of failed rows in summary' do
          unimported = subject.import csv_with_wrong_rows
          assert_equal 1, unimported.count
        end
      end
    end
  end
end