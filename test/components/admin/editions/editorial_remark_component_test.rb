# frozen_string_literal: true

require "test_helper"

class Admin::Editions::EditorialRemarkComponentTest < ViewComponent::TestCase
  test "it constructs output based on the editorial remark when an author is present" do
    editorial_remark = build_stubbed(:editorial_remark, created_at: Time.zone.local(2020, 1, 1, 11, 11))
    author = editorial_remark.author
    render_inline(Admin::Editions::EditorialRemarkComponent.new(editorial_remark:))

    assert_equal page.find("h4").text, "Internal note"
    assert_equal page.all("p")[0].text.strip, editorial_remark.body
    assert_equal page.all("p")[1].text.strip, "1 January 2020 11:11am by #{author.name}"
  end

  test "it constructs output based on the editorial remark when an author is absent" do
    editorial_remark = build_stubbed(:editorial_remark, author: nil, created_at: Time.zone.local(2020, 1, 1, 11, 11))

    render_inline(Admin::Editions::EditorialRemarkComponent.new(editorial_remark:))

    assert_equal page.find("h4").text, "Internal note"
    assert_equal page.all("p")[0].text.strip, editorial_remark.body
    assert_equal page.all("p")[1].text.strip, "1 January 2020 11:11am by User (removed)"
  end
end
