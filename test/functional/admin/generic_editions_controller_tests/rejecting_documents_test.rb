require "test_helper"

class Admin::GenericEditionsController::RejectingDocumentsTest < ActionController::TestCase
  include TaxonomyHelper
  tests Admin::GenericEditionsController

  setup do
    login_as :writer
  end

  view_test "displays the 'Reject' button for privileged users " do
    login_as :departmental_editor
    edition = create(:submitted_edition)
    stub_publishing_api_expanded_links_with_taxons(edition.content_id, [])
    GenericEdition.stubs(:find).with(edition.to_param).returns(edition)

    get :show, params: { id: edition }
    assert_select reject_button_selector(edition), count: 1
  end

  view_test "doesn't display the 'Reject' button for unprivileged users" do
    edition = create(:edition)
    stub_publishing_api_expanded_links_with_taxons(edition.content_id, [])
    GenericEdition.stubs(:find).with(edition.to_param).returns(edition)

    get :show, params: { id: edition }
    refute_select reject_button_selector(edition)
  end

  view_test "should show who rejected the edition" do
    edition = create(:rejected_edition, edition_authors: [create(:edition_author, user: current_user)])
    stub_publishing_api_expanded_links_with_taxons(edition.content_id, [])

    get :show, params: { id: edition }
    assert_select ".app-c-inset-prompt__body a", text: current_user.name
  end

  view_test "should not show the editorial remarks section" do
    edition = create(:submitted_edition)
    stub_publishing_api_expanded_links_with_taxons(edition.content_id, [])

    get :show, params: { id: edition }
    refute_select "#editorial_remarks .editorial_remark"
  end

  view_test "should show the list of editorial remarks" do
    edition = create(:rejected_edition)
    remark = edition.editorial_remarks.create!(body: "editorial-remark-body", author: current_user)
    stub_publishing_api_expanded_links_with_taxons(edition.content_id, [])

    get :show, params: { id: edition }
    assert_select "#history_tab" do
      assert_select ".app-view-editions-editorial-remark__list-item", text: /editorial-remark-body/
      assert_select ".app-view-editions-editorial-remark__list-item a", text: current_user.name
      assert_select "time.datetime[datetime='#{remark.created_at.iso8601}']"
    end
  end
end
