require 'test_helper'

class AddonTest < ActiveSupport::TestCase

  describe 'state transitions' do
    test 'goes from active to disabled and back' do
      addon = Addon.new
      assert_have_state addon, :disabled
      assert_transitions_from addon, :disabled, to: :active, on_event: :publish
      assert_transitions_from addon, :active, to: :disabled, on_event: :disable
    end

    test 'allows to mark addon as beta'  do
      addon = Addon.new
      assert_have_state addon, :disabled
      assert_transitions_from addon, :disabled, to: :beta, on_event: :launch_beta
      assert_transitions_from addon, :beta, to: :disabled, on_event: :disable
    end

    test 'adds slug to created base price' do
      addon = Addon.new name: 'Product groups'
      assert_nil addon.slug

      addon.save
      assert_equal 'product_groups', addon.slug
    end
  end
end
