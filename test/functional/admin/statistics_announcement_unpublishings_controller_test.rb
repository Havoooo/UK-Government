require "test_helper"

class Admin::StatisticsAnnouncementUnpublishingsControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::PublishingApi

  setup do
    @user = login_as(:gds_editor)
    @announcement = create(:statistics_announcement)
  end

  should_be_an_admin_controller

  test "GDS Editor permission required to unpublish" do
    login_as :departmental_editor
    get :new, params: { statistics_announcement_id: @announcement.id }
    assert_response 403
  end

  test "Managing Editor permission allowed to unpublish" do
    login_as :managing_editor
    get :new, params: { statistics_announcement_id: @announcement.id }
    assert_response 200
  end

  view_test "GET :new renders a form with cancel a release" do
    get :new, params: { statistics_announcement_id: @announcement }

    assert_response :success
    assert_select "input[name='statistics_announcement[redirect_url]']"
    assert_select "a.govuk-link", text: "cancel the release", count: 1
  end

  view_test "GET :new with a cancelled announcement doesn't render the cancel release link" do
    get :new, params: { statistics_announcement_id: create(:cancelled_statistics_announcement) }

    assert_response :success
    assert_select "input[name='statistics_announcement[redirect_url]']"
    assert_select "a.govuk-link", text: "cancel the release", count: 0
  end

  test "POST :create with invalid params rerenders the form" do
    post :create,
         params: { statistics_announcement_id: @announcement,
                   statistics_announcement: {
                     redirect_url: "https://youtube.com",
                   } }

    assert_template :new
  end

  test "POST :create with valid params unpublishes the announcement" do
    redirect_url = "https://www.test.gov.uk/example"

    stub_publishing_api_destroy_intent(@announcement.base_path)

    post :create,
         params: { statistics_announcement_id: @announcement,
                   statistics_announcement: {
                     redirect_url:,
                   } }

    @announcement.reload
    assert_redirected_to admin_statistics_announcements_path
    assert_equal redirect_url, @announcement.redirect_url
    assert @announcement.unpublished?
  end
end
