require "test_helper"

class EditionUnwithdrawerTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApi

  setup do
    @edition = FactoryBot.create(:published_edition, state: "withdrawn")
    @user = FactoryBot.create(:user)
    stub_any_publishing_api_call
  end

  test "initialize raises an error unless the edition is withdrawn" do
    @edition = FactoryBot.create(:published_edition, state: "published")
    unwithdraw

    assert_equal ["An edition that is published cannot be unwithdrawn"], @unwithdrawer.failure_reasons
  end

  test "unwithdraw performs steps in a transaction" do
    Edition.any_instance.stubs(:create_draft).raises("Something bad happened here.")

    assert_raises RuntimeError do
      unwithdraw
    end
    @edition.reload

    assert_equal "withdrawn", @edition.state
  end

  test "unwithdraw updates the state of the original edition to superseded" do
    unwithdraw
    @edition.reload
    assert_equal "superseded", @edition.state
  end

  test "unwithdraw publishes a draft of the withdrawn edition" do
    unwithdrawn_edition = unwithdraw
    assert unwithdrawn_edition.published?
    assert unwithdrawn_edition.minor_change
    assert_equal @edition.document, unwithdrawn_edition.document
    assert_equal @user, unwithdrawn_edition.editorial_remarks.first.author
    assert_equal "Unwithdrawn", unwithdrawn_edition.editorial_remarks.first.body
  end

  test "unwithdraw handles legacy withdrawn editions" do
    edition = FactoryBot.create(:published_edition, state: "withdrawn")

    unwithdrawn_edition = unwithdraw(edition)

    assert unwithdrawn_edition.published?
    assert unwithdrawn_edition.minor_change
    assert_equal edition.document, unwithdrawn_edition.document
    assert_equal @user, unwithdrawn_edition.editorial_remarks.first.author
    assert_equal "Unwithdrawn", unwithdrawn_edition.editorial_remarks.first.body
  end

  test "unwithdraw sends the new edition to the publishing-api" do
    unwithdraw
    assert_publishing_api_put_content(@edition.content_id)
    assert_publishing_api_publish(@edition.content_id)
  end

  def unwithdraw(edition = nil)
    edition ||= @edition
    @unwithdrawer = EditionUnwithdrawer.new(edition, user: @user)
    @unwithdrawer.perform!
    edition.document.live_edition
  end
end
