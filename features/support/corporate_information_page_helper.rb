module CorporateInformationPageHelper
  def upload_pdf_to_corporate_information_page(page)
    visit admin_organisation_path(page.organisation)
    click_link "Corporate information pages"
    click_link page.title
    click_link "Modify attachments"
    upload_new_attachment(pdf_attachment, "A PDF attachment")
  end

  def insert_attachment_markdown_into_corporate_information_page_body(attachment, page)
    visit admin_organisation_path(page.organisation)
    click_link "Corporate information pages"
    click_link page.title
    click_link "Edit draft"
    markdown = find_markdown_snippet_to_insert_attachment(attachment)
    fill_in "Body", with: "#{page.body}\n\n#{markdown}"
    click_button "Save and continue"
    click_button "Update and review specialist topic tags"
  end

  def check_attachment_appears_on_corporate_information_page(attachment, page)
    visit page.organisation.public_path
    click_link page.title

    expect(page).to have_selector(".attachment-details .title", text: attachment.title)
  end
end

World(CorporateInformationPageHelper)
