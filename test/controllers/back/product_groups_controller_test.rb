require 'test_helper'

module Back
  class ProductGroupsControllerTest < ActionDispatch::IntegrationTest
    setup do
      user = create :user
      sign_in user
      @store = create :store, user: user
    end

    describe 'GET #index' do
      test "responds with success" do
        get back_product_groups_url
        assert_response :success
      end
    end

    describe 'GET #new' do
      test "responds with success" do
        get new_back_product_group_url
        assert_response :success
      end
    end

    describe 'POST #create' do
      let(:params) { { product_group: attributes_for(:product_group) } }

      test "creates product_group" do
        assert_difference('ProductGroup.count') do
          post back_product_groups_url, params: params
        end
      end

      test 'redirects to groups index' do
        post back_product_groups_url, params: params
        product_group = ProductGroup.last
        assert_redirected_to back_product_group_url(product_group)
      end
    end

    describe 'GET #show' do
      setup do
        @product_group = create :product_group, store: @store
      end

      test "responds with success" do
        get back_product_group_url(@product_group)
        assert_response :success
      end
    end

    describe 'GET #edit' do
      setup do
        @product_group = create :product_group, store: @store
      end

      test "responds with success" do
        get edit_back_product_group_url(@product_group)
        assert_response :success
      end
    end

    describe 'PATCH #update' do
      let(:params) { { product_group: { name: 'new_name' } } }
      setup do
        @product_group = create :product_group, store: @store, name: 'old_name'
      end

      test "updates product group" do
        patch back_product_group_url(@product_group), params: params
        assert_equal 'new_name', @product_group.reload.name
      end

      test "redirects to product groups index" do
        patch back_product_group_url(@product_group), params: params
        assert_redirected_to back_product_group_url(@product_group)
      end
    end

    describe 'DELETE #destroy' do
      setup do
        @product_group = create :product_group, store: @store
      end

      test "destroys product group" do
        assert_difference('ProductGroup.count', -1) do
          delete back_product_group_url(@product_group)
        end
      end

      test 'redirects to index' do
        delete back_product_group_url(@product_group)
        assert_redirected_to back_product_groups_url
      end
    end
  end
end
