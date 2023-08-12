require "test_helper"

class Admin::EditorialRemarksControllerTest < ActionController::TestCase
  setup do
    @logged_in_user = login_as :departmental_editor
  end

  should_be_an_admin_controller

  view_test "should render the edition title and body to give context to the person rejecting" do
    edition = create(:submitted_publication, title: "edition-title", body: "edition-body")
    get :new, params: { edition_id: edition }

    assert_select "#{record_css_selector(edition)} .app-view-editions-edition__document__title", text: "edition-title"
    assert_select "#{record_css_selector(edition)} .app-view-editions-edition__document__body", text: "edition-body"
  end

  view_test "should render the editorial remark form for a statistical data set" do
    StatisticalDataSet.stubs(access_limited_by_default?: false)
    edition = create(:draft_statistical_data_set, title: "edition-title", body: "edition-body")
    get :new, params: { edition_id: edition }
    assert_select "form#new_editorial_remark"
  end

  view_test "should render the editorial remark form for a document collection" do
    edition = create(:draft_document_collection, title: "collection-title", body: "collection-body")
    get :new, params: { edition_id: edition }
    assert_select "form#new_editorial_remark"
  end

  test "should redirect to the edition" do
    edition = create(:submitted_speech)
    post :create, params: { edition_id: edition, editorial_remark: { body: "editorial-remark-body" } }
    assert_redirected_to admin_speech_path(edition)
  end

  test "should create an editorial remark" do
    edition = create(:submitted_publication)
    post :create, params: { edition_id: edition, editorial_remark: { body: "editorial-remark-body" } }

    edition.reload
    assert_equal 1, edition.editorial_remarks.length
    assert_equal @logged_in_user, edition.editorial_remarks.first.author
    assert_equal "editorial-remark-body", edition.editorial_remarks.first.body
  end

  view_test "should explain why the editorial remark could not be saved" do
    edition = create(:submitted_consultation)
    post :create, params: { edition_id: edition, editorial_remark: { body: "" } }
    assert_template "new"
    assert_select ".gem-c-error-summary"
  end

  test "should prevent access to inaccessible editions" do
    protected_edition = create(:submitted_publication, access_limited: true)

    get :new, params: { edition_id: protected_edition.id }
    assert_response :forbidden
    get :create, params: { edition_id: protected_edition.id }
    assert_response :forbidden
  end

  test "should redirect to the edition on deletion" do
    @logged_in_user.permissions << "GDS Admin"
    edition = build(:submitted_speech)
    editorial_remark = create(:editorial_remark, edition:)
    post :destroy, params: { id: editorial_remark }
    assert_redirected_to admin_speech_path(editorial_remark.edition)
  end

  test "should forbid deletion without GDS Admin permission" do
    editorial_remark = create(:editorial_remark)
    post :destroy, params: { id: editorial_remark }
    assert_response :forbidden
  end
end
