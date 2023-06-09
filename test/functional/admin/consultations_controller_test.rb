require "test_helper"

class Admin::ConsultationsControllerTest < ActionController::TestCase
  include TaxonomyHelper

  setup do
    login_as :writer
    @current_user.permissions << "Preview design system"
    ConsultationResponseForm.any_instance.stubs(:consultation_participation).returns(stub(consultation: stub(auth_bypass_id: "auth bypass id")))
  end

  should_be_an_admin_controller

  should_allow_creating_of :consultation
  should_allow_editing_of :consultation

  should_allow_organisations_for :consultation
  should_prevent_modification_of_unmodifiable :consultation
  should_allow_alternative_format_provider_for :consultation
  should_allow_scheduled_publication_of :consultation
  should_allow_access_limiting_of :consultation
  should_render_govspeak_history_and_fact_checking_tabs_for :consultation

  context "#new" do
    view_test "displays consultation fields" do
      get :new

      assert_select "form#new_edition" do
        assert_select "textarea[name='edition[summary]']"
        assert_select "select[name*='edition[opening_at']", count: 5
        assert_select "select[name*='edition[closing_at']", count: 5
        assert_select "input[type='text'][name='edition[consultation_participation_attributes][link_url]']"
        assert_select "input[type='text'][name='edition[consultation_participation_attributes][email]']"
        assert_select "input[type='text'][name='edition[consultation_participation_attributes][consultation_response_form_attributes][title]']"
        assert_select "input[type='file'][name='edition[consultation_participation_attributes][consultation_response_form_attributes][consultation_response_form_data_attributes][file]']"
      end
    end
  end

  context "#create" do
    test "should create a new consultation" do
      attributes = controller_attributes_for(
        :consultation,
        consultation_participation_attributes: {
          link_url: "http://participation.com",
          email: "countmein@participation.com",
          consultation_response_form_attributes: {
            title: "the title of the response form",
            consultation_response_form_data_attributes: {
              file: upload_fixture("two-pages.pdf"),
            },
          },
        },
      )

      post :create, params: { edition: attributes }

      consultation = Consultation.last
      response_form = consultation.consultation_participation.consultation_response_form
      assert_equal attributes[:summary], consultation.summary
      assert_equal attributes[:opening_at], consultation.opening_at
      assert_equal attributes[:closing_at], consultation.closing_at
      assert_equal "http://participation.com", consultation.consultation_participation.link_url
      assert_equal "countmein@participation.com", consultation.consultation_participation.email
      assert_equal "the title of the response form", response_form.title
      assert response_form.consultation_response_form_data.file.present?
    end

    test "should not persist external_url if the external checkbox is not checked" do
      attributes = controller_attributes_for(
        :consultation,
        external: "0",
        external_url: "http://participation.com",
        consultation_participation_attributes: {
          link_url: "http://participation.com",
          email: "countmein@participation.com",
          consultation_response_form_attributes: {
            title: "the title of the response form",
            consultation_response_form_data_attributes: {
              file: upload_fixture("two-pages.pdf"),
            },
          },
        },
      )

      post :create, params: { edition: attributes }

      consultation = Consultation.last
      assert consultation.external_url.blank?
    end

    test "should create a new consultation without consultation participation if participation fields are all blank" do
      attributes = controller_attributes_for(
        :consultation,
        consultation_participation_attributes: {
          link_url: nil,
          email: nil,
          consultation_response_form_attributes: {
            title: nil,
            consultation_response_form_data_attributes: {
              file: nil,
            },
          },
        },
      )

      post :create, params: { edition: attributes }

      consultation = Consultation.last
      assert_nil consultation.consultation_participation
    end

    view_test "should still display the cached form file when creating a consultation with invalid data but valid form file" do
      attributes = controller_attributes_for(
        :consultation,
        consultation_participation_attributes: {
          link_url: nil,
          email: nil,
          consultation_response_form_attributes: {
            title: nil,
            consultation_response_form_data_attributes: {
              file: upload_fixture("two-pages.pdf"),
            },
          },
        },
      )

      post :create, params: { edition: attributes }

      assert_select "form#new_edition" do
        assert_select "input[name='edition[consultation_participation_attributes][consultation_response_form_attributes][consultation_response_form_data_attributes][file_cache]'][value$='two-pages.pdf']"
        assert_select ".govuk-body.already-uploaded", text: "two-pages.pdf already uploaded"
      end
    end
  end

  context "#show" do
    view_test "should render the summary" do
      draft_consultation = create(:draft_consultation, summary: "a-simple-summary")
      stub_publishing_api_expanded_links_with_taxons(draft_consultation.content_id, [])

      get :show, params: { id: draft_consultation }
      assert_select ".page-header .govuk-body-lead", text: "a-simple-summary"
    end

    view_test "should render the preview link for foreign only consultations" do
      french_consultation = create(:draft_consultation, primary_locale: "fr")
      french_consultation.translations.first.update!(locale: "fr")

      stub_publishing_api_expanded_links_with_taxons(french_consultation.content_id, [])

      get :show, params: { id: french_consultation }
      assert_select ".app-view-edition-summary__section a", text: "Preview on website  (opens in new tab)", href: french_consultation.public_url(draft: true)
    end
  end

  context "#edit" do
    view_test "should display consultation fields" do
      response_form = create(:consultation_response_form)
      participation = create(:consultation_participation, consultation_response_form: response_form)
      consultation = create(:consultation, consultation_participation: participation)

      get :edit, params: { id: consultation }

      assert_select "form#edit_edition" do
        assert_select "textarea[name='edition[summary]']"
        assert_select "select[name*='edition[opening_at']", count: 5
        assert_select "select[name*='edition[closing_at']", count: 5
        assert_select "input[type='text'][name='edition[consultation_participation_attributes][link_url]']"
        assert_select "input[type='text'][name='edition[consultation_participation_attributes][email]']"
        assert_select "textarea[name='edition[consultation_participation_attributes][postal_address]']"
        assert_select "input[type='hidden'][name='edition[consultation_participation_attributes][consultation_response_form_attributes][id]'][value='#{response_form.id}']"
        assert_select "input[type='text'][name='edition[consultation_participation_attributes][consultation_response_form_attributes][title]']"
        assert_select "input[type='hidden'][name='edition[consultation_participation_attributes][consultation_response_form_attributes][consultation_response_form_data_attributes][id]'][value='#{response_form.consultation_response_form_data.id}']"
        assert_select "input[type='file'][name='edition[consultation_participation_attributes][consultation_response_form_attributes][consultation_response_form_data_attributes][file]']"
      end
    end
  end

  context "#update" do
    test "should save modified consultation attributes" do
      consultation = create(:consultation)

      put :update,
          params: { id: consultation,
                    edition: {
                      summary: "new-summary",
                      opening_at: 1.day.ago,
                      closing_at: 50.days.from_now,
                      consultation_participation_attributes: {
                        link_url: "http://consult.com",
                        email: "tell-us-what-you-think@gov.uk",
                      },
                    } }

      consultation.reload
      assert_equal "new-summary", consultation.summary
      assert_equal 1.day.ago, consultation.opening_at
      assert_equal 50.days.from_now, consultation.closing_at
      assert_equal "http://consult.com", consultation.consultation_participation.link_url
      assert_equal "tell-us-what-you-think@gov.uk", consultation.consultation_participation.email
    end

    test "should save consultation without consultation participation if participation fields are all blank" do
      consultation = create(:consultation)

      put :update,
          params: { id: consultation,
                    edition: {
                      consultation_participation_attributes: {
                        link_url: nil,
                        email: nil,
                      },
                    } }

      consultation.reload
      assert_nil consultation.consultation_participation
    end

    view_test "should not allow removal of response form without explicit action" do
      response_form = create(:consultation_response_form)
      participation = create(:consultation_participation, consultation_response_form: response_form)
      consultation = create(:consultation, consultation_participation: participation)

      put :update,
          params: { id: consultation,
                    edition: {
                      consultation_participation_attributes: {
                        id: participation.id,
                        consultation_response_form_attributes: {
                          id: response_form.id,
                          _destroy: "1",
                        },
                      },
                    } }

      refute_select ".errors"
      consultation.reload
      assert_not_nil consultation.consultation_participation.consultation_response_form
    end

    view_test "should respect the attachment_action for response forms to keep it" do
      two_pages_pdf = upload_fixture("two-pages.pdf")
      greenpaper_pdf = upload_fixture("greenpaper.pdf")

      response_form = create(:consultation_response_form, file: two_pages_pdf)
      participation = create(:consultation_participation, consultation_response_form: response_form)
      consultation = create(:consultation, consultation_participation: participation)

      put :update,
          params: { id: consultation,
                    edition: {
                      consultation_participation_attributes: {
                        id: participation.id,
                        consultation_response_form_attributes: {
                          id: response_form.id,
                          attachment_action: "keep",
                          _destroy: "1",
                          consultation_response_form_data_attributes: {
                            id: response_form.consultation_response_form_data.id,
                            file: greenpaper_pdf,
                          },
                        },
                      },
                    } }

      refute_select ".errors"
      consultation.reload
      assert_not_nil consultation.consultation_participation.consultation_response_form
      assert_equal "two-pages.pdf", consultation.consultation_participation.consultation_response_form.consultation_response_form_data.carrierwave_file
    end

    view_test "should respect the attachment_action for response forms to remove it" do
      AssetManagerDeleteAssetWorker.stubs(:perform_async)

      response_form = create(:consultation_response_form)
      participation = create(:consultation_participation, consultation_response_form: response_form)
      consultation = create(:consultation, consultation_participation: participation)

      put :update,
          params: { id: consultation,
                    edition: {
                      consultation_participation_attributes: {
                        id: participation.id,
                        consultation_response_form_attributes: {
                          id: response_form.id,
                          attachment_action: "remove",
                        },
                      },
                    } }

      refute_select ".errors"
      consultation.reload
      assert_nil consultation.consultation_participation.consultation_response_form
      assert_raise(ActiveRecord::RecordNotFound) do
        response_form.consultation_response_form_data.reload
      end
      assert_raise(ActiveRecord::RecordNotFound) do
        response_form.reload
      end
    end

    view_test "should respect the attachment_action for response forms to replace it" do
      Services.asset_manager.stubs(:whitehall_asset).returns("id" => "http://asset-manager/assets/asset-id")
      Services.asset_manager.stubs(:delete_asset)

      two_pages_pdf = upload_fixture("two-pages.pdf")
      greenpaper_pdf = upload_fixture("greenpaper.pdf")

      response_form = create(:consultation_response_form, file: two_pages_pdf)
      participation = create(:consultation_participation, consultation_response_form: response_form)
      consultation = create(:consultation, consultation_participation: participation)

      put :update,
          params: { id: consultation,
                    edition: {
                      consultation_participation_attributes: {
                        id: participation.id,
                        consultation_response_form_attributes: {
                          id: response_form.id,
                          attachment_action: "replace",
                          _destroy: "1",
                          consultation_response_form_data_attributes: {
                            id: response_form.consultation_response_form_data.id,
                            file: greenpaper_pdf,
                          },
                        },
                      },
                    } }

      refute_select ".errors"
      consultation.reload
      assert_not_nil consultation.consultation_participation.consultation_response_form
      assert_equal "greenpaper.pdf", consultation.consultation_participation.consultation_response_form.consultation_response_form_data.carrierwave_file
    end
  end

private

  def controller_attributes_for(edition_type, attributes = {})
    super.except(:alternative_format_provider).reverse_merge(
      alternative_format_provider_id: create(:alternative_format_provider).id,
    )
  end
end
