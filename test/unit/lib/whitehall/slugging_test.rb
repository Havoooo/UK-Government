require "test_helper"

class SluggingTest < ActiveSupport::TestCase
  test "should try and limit the length of the slug to 150" do
    document = create(:document, sluggable_string: "Availability of technologies for provisioning Home Area Network (HAN) connectivity to electricity and gas metering equipment, communications hub and in-home devices in cases where a 2.4GHz ZigBee wireless HAN will not work effectively")
    assert document.slug.length <= 150
  end

  test "should resolve a conflict" do
    _document1 = create(:document, sluggable_string: "Slug conflict")
    document2 = create(:document, sluggable_string: "Slug conflict")
    assert_equal "slug-conflict--2", document2.slug
  end

  test "should handle document titles with numbers" do
    _document1 = create(:document, sluggable_string: "2010-2015 conflict")
    document2 = create(:document, sluggable_string: "2010-2015 conflict")
    assert_equal "2010-2015-conflict--2", document2.slug
  end

  test "should strip punctuation properly" do
    document = create(:document, sluggable_string: "attorney general's")
    assert_equal "attorney-generals", document.slug
  end
end
