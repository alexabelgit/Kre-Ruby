require 'test_helper'

class StringTest < ActiveSupport::TestCase

  test 'is_number? checks that string is a number' do
    assert "2".is_number?
    refute "abc".is_number?
    assert "3.1415".is_number?
  end

  describe '#mask_email' do
    test 'replaces all emails with masked symbols in given text' do
      given = "By in no ecstatic wondered disposal my speaking. some@email.com Direct another-email@gmail.com wholly valley or uneasy it at really. Sir wish like said dull and need make. third@mail.ru Sportsman one bed departure rapturous situation disposing his."
      expected = "By in no ecstatic wondered disposal my speaking. ***@***.*** Direct ***@***.*** wholly valley or uneasy it at really. Sir wish like said dull and need make. ***@***.*** Sportsman one bed departure rapturous situation disposing his."
      assert_equal expected, given.mask_email
    end

    test 'masks single given email' do
      assert_equal '***@***.***', 'some.typical.email@corp.edu'.mask_email
    end
  end
end
