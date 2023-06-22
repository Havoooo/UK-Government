When(/^I create a worldwide organisation "([^"]*)" sponsored by the "([^"]*)"$/) do |name, sponsoring_organisation|
  visit new_admin_worldwide_organisation_path
  fill_in "Name", with: name
  fill_in "Logo formatted name", with: name
  select sponsoring_organisation, from: "Sponsoring organisations"
  click_on "Save"
end

When(/^I create a new worldwide organisation "([^"]*)" in "([^"]*)"$/) do |name, location|
  visit new_admin_worldwide_organisation_path
  fill_in "Name", with: name
  fill_in "Logo formatted name", with: name
  select location, from: "World location"
  click_on "Save"
end

Then(/^the "([^"]*)" logo should show correctly with the HMG crest$/) do |name|
  worldwide_organisation = WorldwideOrganisation.find_by(name:)
  expect(page).to have_selector(".gem-c-organisation-logo", text: worldwide_organisation.logo_formatted_name)
end

Then(/^I should see that it is part of the "([^"]*)"$/) do |sponsoring_organisation|
  expect(page).to have_selector(".sponsoring-organisation", text: sponsoring_organisation)
end

Then(/^I should see the worldwide location name "([^"]*)" on the worldwide organisation page$/) do |location_name|
  location = WorldLocation.find_by(name: location_name)
  worldwide_organisation = WorldwideOrganisation.last
  within record_css_selector(worldwide_organisation) do
    expect(page).to have_content(location.name)
  end
end

When(/^I update the worldwide organisation to set the name to "([^"]*)"$/) do |new_title|
  visit edit_admin_worldwide_organisation_path(WorldwideOrganisation.last)
  fill_in "Name", with: new_title
  click_on "Save"
end

When(/^I delete the worldwide organisation$/) do
  @worldwide_organisation = WorldwideOrganisation.last
  visit edit_admin_worldwide_organisation_path(@worldwide_organisation)
  click_on "delete"
end

Given(/^a worldwide organisation "([^"]*)"$/) do |name|
  worg = create(:worldwide_organisation, name:)
  worg.main_office = create(:worldwide_office, worldwide_organisation: worg, title: "Main office for #{name}")
end

Given(/^a worldwide organisation "([^"]*)" exists for the world location "([^"]*)" with translations into "([^"]*)"$/) do |name, _country_name, translation|
  country = create(:world_location, active: true, translated_into: [translation])
  create(:worldwide_organisation, name:, world_locations: [country])
end

When(/^I add an "([^"]*)" office for the home page with address, phone number, and some services$/) do |description|
  service1 = create(:worldwide_service, name: "Dance lessons")
  _service2 = create(:worldwide_service, name: "Courses in advanced sword fighting")
  service3 = create(:worldwide_service, name: "Beard grooming")

  visit admin_worldwide_organisation_worldwide_offices_path(WorldwideOrganisation.last)
  click_link "Add"
  fill_in_contact_details(title: description, feature_on_home_page: "yes")
  select WorldwideOfficeType.all.sample.name, from: "Office type"

  check service1.name
  check service3.name

  click_on "Save"
end

Then(/^I should be able to remove all services from the "(.*?)" office$/) do |description|
  worldwide_office = WorldwideOffice.joins(contact: :translations).where(contact_translations: { title: description }).first
  visit edit_admin_worldwide_organisation_worldwide_office_path(worldwide_organisation_id: WorldwideOrganisation.last.id, id: worldwide_office.id)
  available_services = worldwide_office.services.each { |service| uncheck "worldwide_office_service_ids_#{service.id}" }
  click_on "Save"

  visit edit_admin_worldwide_organisation_worldwide_office_path(worldwide_organisation_id: WorldwideOrganisation.last.id, id: worldwide_office.id)
  available_services.each do |service|
    expect(page).to have_field("worldwide_office_service_ids_#{service.id}", checked: false)
  end
end

Given(/^that the world location "([^"]*)" exists$/) do |country_name|
  create(:world_location, name: country_name, active: true)
end

Given(/^the worldwide organisation "([^"]*)" exists$/) do |worldwide_organisation_name|
  create(:worldwide_organisation, name: worldwide_organisation_name, logo_formatted_name: worldwide_organisation_name)
end

Given(/^a worldwide organisation "([^"]*)" with offices "([^"]*)" and "([^"]*)"$/) do |worldwide_organisation_name, contact_1_title, contact_2_title|
  worldwide_organisation = create(:worldwide_organisation, name: worldwide_organisation_name)
  worldwide_organisation.add_office_to_home_page!(create(:worldwide_office, worldwide_organisation:, contact: create(:contact, title: contact_1_title)))
  worldwide_organisation.add_office_to_home_page!(create(:worldwide_office, worldwide_organisation:, contact: create(:contact, title: contact_2_title)))
end

When(/^I choose "([^"]*)" to be the main office$/) do |contact_title|
  worldwide_office = WorldwideOffice.joins(contact: :translations).where(contact_translations: { title: contact_title }).first
  visit admin_worldwide_organisation_path(WorldwideOrganisation.last)
  click_link "Offices"
  within record_css_selector(worldwide_office) do
    click_button "Set as main office"
  end
end

Then(/^the "([^"]*)" should be marked as the main office$/) do |contact_title|
  admin_worldwide_organisation_worldwide_offices_path(WorldwideOrganisation.last)

  office_container = page.find("h3", text: contact_title).ancestor(".worldwide_office")
  within office_container do
    expect(page).to have_content("(Main office)")
  end
end

When(/^I add default access information to the worldwide organisation$/) do
  visit admin_worldwide_organisation_path(WorldwideOrganisation.last)
  click_link "Access and opening times"
  click_link "Add default access information"
  fill_in "Body", with: "Default body information"
  click_button "Save"
end

Then(/^I should see the default access information on the edit "([^"]*)" office page$/) do |office_name|
  worldwide_organisation = WorldwideOrganisation.last
  worldwide_office = WorldwideOffice.joins(contact: :translations).where(contact_translations: { title: office_name }).first
  visit edit_admin_worldwide_organisation_worldwide_office_access_and_opening_time_path(worldwide_organisation, worldwide_office)

  expect(page).to have_content("Default body information")
end

Then(/^I should see custom access information on the edit "([^"]*)" office page$/) do |office_name|
  worldwide_organisation = WorldwideOrganisation.last
  worldwide_office = WorldwideOffice.joins(contact: :translations).where(contact_translations: { title: office_name }).first
  visit edit_admin_worldwide_organisation_worldwide_office_access_and_opening_time_path(worldwide_organisation, worldwide_office)

  expect(page).to have_content("Custom body information")
end

Given(/^a worldwide organisation "([^"]*)" with default access information$/) do |name|
  create(:worldwide_organisation, name:, default_access_and_opening_times: "Default body information")
end

When(/^I edit the default access information for the worldwide organisation$/) do
  worldwide_organisation = WorldwideOrganisation.last
  visit admin_worldwide_organisation_path(worldwide_organisation)
  click_link "Access and opening times"
  click_on "Edit"
  fill_in "Body", with: "Edited body information"
  click_button "Save"
end

Given(/^the offices "([^"]*)" and "([^"]*)"$/) do |contact_1_title, contact_2_title|
  worldwide_organisation = WorldwideOrganisation.last
  worldwide_organisation.add_office_to_home_page!(create(:worldwide_office, worldwide_organisation:, contact: create(:contact, title: contact_1_title)))
  worldwide_organisation.add_office_to_home_page!(create(:worldwide_office, worldwide_organisation:, contact: create(:contact, title: contact_2_title)))
end

When(/^I give "([^"]*)" custom access information$/) do |office_name|
  worldwide_organisation = WorldwideOrganisation.last
  worldwide_office = WorldwideOffice.joins(contact: :translations).where(contact_translations: { title: office_name }).first
  visit admin_worldwide_organisation_path(worldwide_organisation)
  click_link "Offices"
  within record_css_selector(worldwide_office) do
    click_on "Customise"
  end

  fill_in "Body", with: "Custom body information"
  click_button "Save"
end

Then(/^I should see the updated default access information$/) do
  expect(page).to have_selector(".govspeak p", text: "Edited body information")
end

When(/^I add a new translation to the worldwide organisation "([^"]*)" with:$/) do |name, table|
  worldwide_organisation = WorldwideOrganisation.find_by!(name:)
  add_translation_to_worldwide_organisation(worldwide_organisation, table.rows_hash)
end

Then(/^I should see the language "([^"]*)" \("([^"]*)"\) for "([^"]*)" \("([^"]*)"\) when viewing the worldwide organisation translations$/) do |language, language_in_english, worldwide_organisation, worldwide_organisation_in_english|
  visit admin_worldwide_organisation_translations_path(WorldwideOrganisation.last)

  click_link language
  expect(page).to have_content("Edit ‘#{language} (#{language_in_english})’ translation for: #{worldwide_organisation_in_english}")
  expect(page).to have_field("Name", with: worldwide_organisation)
end

Given(/^a worldwide organisation "([^"]*)" exists with a translation for the locale "([^"]*)"$/) do |name, native_locale_name|
  locale_code = Locale.find_by_language_name(native_locale_name).code
  country = create(:world_location, active: true, world_location_type: "world_location")
  create(:worldwide_organisation, name:, world_locations: [country], translated_into: [locale_code])
end

When(/^I edit the "([^"]*)" translation for the worldwide organisation "([^"]*)" setting:$/) do |locale, name, table|
  edit_translation_for_worldwide_organisation(locale, name, table.rows_hash)
end

Then(/^I should be able to see "([^"]*)" in the list of worldwide organisations$/) do |worldwide_organisation_name|
  visit admin_worldwide_organisations_path
  within ".table" do
    expect(page).to have_content(worldwide_organisation_name)
  end
end

Then(/^I should not be able to see "([^"]*)" in the list of worldwide organisations$/) do |worldwide_organisation_name|
  visit admin_worldwide_organisations_path
  within ".table" do
    expect(page).to_not have_content(worldwide_organisation_name)
  end
end

Then(/^I should see a create record in the audit trail for the worldwide organisation/) do
  visit admin_worldwide_organisation_path(WorldwideOrganisation.last)

  history_component = page.find(".audit-history-component")

  within history_component do
    expect(page).to have_content("Document created")
    expect(page).to have_content(@user.name)
  end
end

Then(/^I should see an update record in the audit trail for the worldwide organisation/) do
  visit admin_worldwide_organisation_path(WorldwideOrganisation.last)

  history_component = page.find(".audit-history-component", match: :first)

  within history_component do
    expect(page).to have_content("Document updated")
    expect(page).to have_content(@user.name)
  end
end

Then(/^Then I should see the corporate information on the worldwide organisation corporate information pages page/) do
  worldwide_organisation = WorldwideOrganisation.last
  visit admin_worldwide_organisation_corporate_information_pages_path(worldwide_organisation)

  corporate_information_page = worldwide_organisation.corporate_information_pages.last

  expect(page).to have_content(corporate_information_page.title)

  click_link corporate_information_page.title
  expect(page).to have_content(corporate_information_page.title)
end
