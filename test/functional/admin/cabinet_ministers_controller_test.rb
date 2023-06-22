require "test_helper"

class Admin::CabinetMinistersControllerTest < ActionController::TestCase
  setup do
    login_as :gds_editor
  end

  should_be_an_admin_controller

  def organisation
    @organisation ||= create(:organisation)
  end

  test "should reorder ministerial roles" do
    @request.env["HTTP_REFERER"] = Plek.website_root + reorder_cabinet_minister_roles_admin_cabinet_ministers_path
    role2 = create(:ministerial_role, name: "Non-Executive Director", cabinet_member: true, organisations: [organisation])
    role1 = create(:ministerial_role, name: "Prime Minister", cabinet_member: true, organisations: [organisation])

    put :update,
        params: {
          roles: {
            ordering: {
              role1.id.to_s => 0,
              role2.id.to_s => 1,
            },
          },
        }

    assert_equal MinisterialRole.cabinet.order(:seniority).to_a, [role1, role2]
    assert_redirected_to "#{admin_cabinet_ministers_path}#cabinet_minister"
  end

  test "should reorder people who also attend cabinet" do
    @request.env["HTTP_REFERER"] = Plek.website_root + reorder_also_attends_cabinet_roles_admin_cabinet_ministers_path
    role2 = create(:ministerial_role, name: "Chief Whip and Parliamentary Secretary to the Treasury", attends_cabinet_type_id: 2, organisations: [organisation])
    role1 = create(:ministerial_role, name: "Minister without Portfolio", attends_cabinet_type_id: 1, organisations: [organisation])

    put :update,
        params: {
          roles: {
            ordering: {
              role1.id.to_s => 0,
              role2.id.to_s => 1,
            },
          },
        }

    assert_equal MinisterialRole.also_attends_cabinet.order(:seniority).to_a, [role1, role2]
    assert_redirected_to "#{admin_cabinet_ministers_path}#also_attends_cabinet"
  end

  test "should reorder whips as part of the same request" do
    @request.env["HTTP_REFERER"] = Plek.website_root + reorder_whip_roles_admin_cabinet_ministers_path
    role2 = create(:ministerial_role, name: "Whip 1", whip_organisation_id: 2, organisations: [organisation])
    role1 = create(:ministerial_role, name: "Whip 2", whip_organisation_id: 2, organisations: [organisation])

    put :update,
        params: {
          whips: {
            ordering: {
              role1.id.to_s => 0,
              role2.id.to_s => 1,
            },
          },
        }

    assert_equal MinisterialRole.whip.order(:seniority).to_a, [role2, role1]
    assert_equal MinisterialRole.whip.order(:whip_ordering).to_a, [role1, role2]
    assert_redirected_to "#{admin_cabinet_ministers_path}#whips"
  end

  test "should reorder ministerial organisations" do
    @request.env["HTTP_REFERER"] = Plek.website_root + reorder_ministerial_organisations_admin_cabinet_ministers_path
    org2 = create(:organisation)
    org1 = create(:organisation)

    put :update,
        params: {
          organisation: {
            ordering: {
              org1.id.to_s => 0,
              org2.id.to_s => 1,
            },
          },
        }

    assert_equal Organisation.order(:ministerial_ordering), [org1, org2]
    assert_redirected_to "#{admin_cabinet_ministers_path}#organisations"
  end

  view_test "should list cabinet ministers and ministerial organisations in separate tabs, in the correct order, with reorder links" do
    minister1 = create(:ministerial_role, name: "Non-Executive Director", cabinet_member: true, organisations: [organisation], seniority: 1)
    minister2 = create(:ministerial_role, name: "Prime Minister", cabinet_member: true, organisations: [organisation], seniority: 0)

    also_attends_cabinet1 = create(:ministerial_role, name: "Chief Whip and Parliamentary Secretary to the Treasury", attends_cabinet_type_id: 2, organisations: [organisation], seniority: 1)
    also_attends_cabinet2 = create(:ministerial_role, name: "Minister without Portfolio", attends_cabinet_type_id: 1, organisations: [organisation], seniority: 0)

    whip1 = create(:ministerial_role, name: "Whip 1", whip_organisation_id: 2, organisations: [organisation], whip_ordering: 1)
    whip2 = create(:ministerial_role, name: "Whip 2", whip_organisation_id: 2, organisations: [organisation], whip_ordering: 0)

    org1 = create(:ministerial_department, ministerial_ordering: 1)
    org2 = create(:ministerial_department, ministerial_ordering: 0)

    get :show

    assert_tab_has_href_and_ordered_roles("#cabinet_minister", reorder_cabinet_minister_roles_admin_cabinet_ministers_path, [minister2, minister1])
    assert_tab_has_href_and_ordered_roles("#also_attends_cabinet", reorder_also_attends_cabinet_roles_admin_cabinet_ministers_path, [also_attends_cabinet2, also_attends_cabinet1])
    assert_tab_has_href_and_ordered_roles("#whips", reorder_whip_roles_admin_cabinet_ministers_path, [whip2, whip1])
    assert_tab_has_href_and_ordered_roles("#organisations", reorder_ministerial_organisations_admin_cabinet_ministers_path, [org2, org1])
  end

  view_test "GET :reorder_cabinet_minister_roles should assign roles correctly and the cancel_path should have the correct anchor" do
    minister1 = create(:ministerial_role, name: "Non-Executive Director", cabinet_member: true, organisations: [organisation], seniority: 1)
    minister2 = create(:ministerial_role, name: "Prime Minister", cabinet_member: true, organisations: [organisation], seniority: 0)

    get :reorder_cabinet_minister_roles

    assert_response :success
    assert_template "reorder_cabinet_minister_roles"
    assert_equal assigns(:roles), [minister2, minister1]
    assert_select ".govuk-link[href='#{admin_cabinet_ministers_path}#cabinet_minister']", text: "Cancel"
  end

  view_test "GET :reorder_also_attends_cabinet_roles should assign roles correctly and the cancel_path should have the correct anchor" do
    also_attends_cabinet1 = create(:ministerial_role, name: "Chief Whip and Parliamentary Secretary to the Treasury", attends_cabinet_type_id: 2, organisations: [organisation], seniority: 1)
    also_attends_cabinet2 = create(:ministerial_role, name: "Minister without Portfolio", attends_cabinet_type_id: 1, organisations: [organisation], seniority: 0)

    get :reorder_also_attends_cabinet_roles

    assert_response :success
    assert_template "reorder_also_attends_cabinet_roles"
    assert_equal assigns(:roles), [also_attends_cabinet2, also_attends_cabinet1]
    assert_select ".govuk-link[href='#{admin_cabinet_ministers_path}#also_attends_cabinet']", text: "Cancel"
  end

  view_test "GET :reorder_whip_roles should assign roles correctly and the cancel_path should have the correct anchor" do
    whip1 = create(:ministerial_role, name: "Whip 1", whip_organisation_id: 2, organisations: [organisation], whip_ordering: 1)
    whip2 = create(:ministerial_role, name: "Whip 2", whip_organisation_id: 2, organisations: [organisation], whip_ordering: 0)

    get :reorder_whip_roles

    assert_response :success
    assert_template "reorder_whip_roles"
    assert_equal assigns(:roles), [whip2, whip1]
    assert_select ".govuk-link[href='#{admin_cabinet_ministers_path}#whips']", text: "Cancel"
  end

  view_test "GET :reorder_ministerial_organisations should assign roles correctly and the cancel_path should have the correct anchor" do
    org1 = create(:ministerial_department, ministerial_ordering: 1)
    org2 = create(:ministerial_department, ministerial_ordering: 0)

    get :reorder_ministerial_organisations

    assert_response :success
    assert_template "reorder_ministerial_organisations"
    assert_equal assigns(:organisations), [org2, org1]
    assert_select ".govuk-link[href='#{admin_cabinet_ministers_path}#organisations']", text: "Cancel"
  end

private

  def assert_tab_has_href_and_ordered_roles(id, href, roles)
    assert_select id do
      assert_select ".govuk-link", text: "Reorder list" do |links|
        assert links.first[:href] == href
      end

      roles.each_with_index do |role, index|
        assert_select ".govuk-table__row:nth-child(#{index + 1}) td:first-child", role.name
      end
    end
  end
end
