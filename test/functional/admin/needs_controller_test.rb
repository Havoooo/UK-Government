require "test_helper"
require "gds_api/test_helpers/publishing_api"

class Admin::NeedsControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::PublishingApi

  def setup
    login_as :user
    @document = create(:edition, :with_document).document

    @need1 = {
      "content_id" => SecureRandom.uuid,
      "format" => "need",
      "title" => "Need #1",
      "base_path" => "/government/needs/need-1",
      "links" => {},
    }
    @need2 = {
      "content_id" => SecureRandom.uuid,
      "format" => "need",
      "title" => "Need #2",
      "base_path" => "/government/needs/need-2",
      "links" => {},
    }

    stub_request(
      :get,
      %r{\A#{Plek.find('publishing-api')}/v2/links},
    ).to_return(body: { links: { meets_user_needs: [@need1, @need2] } }.to_json)

    stub_publishing_api_has_linkables([@need1, @need2], document_type: "need")
  end

  test "associate user needs with a document" do
    edition = create(:edition_with_document)
    document = edition.document
    need_content_ids = [SecureRandom.uuid, SecureRandom.uuid]

    patch_links_request = stub_request(
      :patch,
      %r{\A#{Plek.find('publishing-api')}/v2/links},
    ).with(body: { links: { meets_user_needs: need_content_ids } })

    post :update, params: { content_id: document.content_id, edition_id: edition.id, need_ids: need_content_ids }

    assert_requested patch_links_request
  end

  view_test "should be possible to update needs for a published edition" do
    edition = create(:edition_with_document)
    document = edition.document

    get :edit, params: { content_id: document.content_id, edition_id: edition.id }

    assert_select "form[action='#{admin_update_needs_path(content_id: document.content_id)}']"
    assert_select "select#need_ids" do
      assert_select "option:not([value=''])", count: 2
    end
  end
end
