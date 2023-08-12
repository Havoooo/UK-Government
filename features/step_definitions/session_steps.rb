Given(/^I am (?:a|an) (writer|editor|admin|GDS editor|GDS admin|importer|managing editor)(?: called "([^"]*)")?$/) do |role, name|
  @user = case role
          when "writer"
            create(:writer, name: (name || "Wally Writer"))
          when "editor"
            create(:departmental_editor, name: (name || "Eddie Depteditor"))
          when "admin"
            create(:user)
          when "GDS editor"
            create(:gds_editor)
          when "GDS admin"
            create(:gds_admin)
          when "importer"
            create(:importer)
          when "managing editor"
            create(:managing_editor)
          end
  @user.permissions << User::Permissions::PREVIEW_CALL_FOR_EVIDENCE
  @user.save!
  login_as @user
end

Given(/^I am (?:an?) (admin|writer|editor|GDS editor) in the organisation "([^"]*)"$/) do |role, organisation_name|
  organisation = Organisation.find_by(name: organisation_name) || create_org_and_stub_content_store(:ministerial_department, name: organisation_name)
  @user = case role
          when "admin"
            create(:user, organisation:)
          when "writer"
            create(:writer, name: "Wally Writer", organisation:)
          when "editor"
            create(:departmental_editor, name: "Eddie Depteditor", organisation:)
          when "GDS editor"
            create(:gds_editor, organisation:)
          end
  login_as @user
end

Given(/^I have the "(.*?)" permission$/) do |perm|
  @user.permissions << perm
  @user.save!
end

Around("@use_real_sso") do |_scenario, block|
  current_sso_env = ENV["GDS_SSO_MOCK_INVALID"]
  ENV["GDS_SSO_MOCK_INVALID"] = "1"
  block.call
  ENV["GDS_SSO_MOCK_INVALID"] = current_sso_env
end
