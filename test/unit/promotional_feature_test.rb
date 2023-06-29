require "test_helper"

class PromotionalFeatureTest < ActiveSupport::TestCase
  test "A feature with three items has reached its limit" do
    feature = create(:promotional_feature)

    3.times do
      assert_not feature.has_reached_item_limit?
      create(:promotional_feature_item, promotional_feature: feature)
    end

    assert feature.has_reached_item_limit?
  end

  test "it sets the ordering value before_save when ordering is blank" do
    organisation = create(:executive_office)
    feature1 = create(:promotional_feature, organisation:)
    feature2 = create(:promotional_feature, organisation:)

    assert_equal feature1.ordering, 1
    assert_equal feature2.ordering, 2
  end

  test "rejects SVG logo uploads" do
    svg_logo = File.open(Rails.root.join("test/fixtures/images/test-svg.svg"))
    promotional_feature = build(:promotional_feature_item, image: svg_logo)

    assert_not promotional_feature.valid?
    binding.pry
    assert promotional_feature.errors.include?("Image is not of an allowed type")
  end
end
