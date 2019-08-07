module Auxillary
  # deep hash conversion to OpenStructs
  def to_open_struct(hash)
    JSON.parse hash.to_json, object_class: OpenStruct
  end

  def assert_same_elements(array_1, array_2)
    assert_equal array_1.sort, array_2.sort
  end
end
