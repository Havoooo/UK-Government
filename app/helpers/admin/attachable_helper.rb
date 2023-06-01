module Admin::AttachableHelper
  def attachable_editing_tabs(attachable, &block)
    case attachable
    when Consultation
      consultation_editing_tabs(attachable, &block)
    when Response
      consultation_editing_tabs(attachable.consultation, &block)
    when Edition
      edition_editing_tabs(attachable, &block)
    else
      tab_navigation_for(attachable, &block)
    end
  end

  def attachment_action_fields(fields, data_object_name = :attachment_data)
    return if fields.object.new_record?

    keep_destroy_or_replace =
      if fields.object[:_destroy].present? && fields.object[:_destroy] == "1"
        "destroy"
      elsif fields.object.send(data_object_name).file_cache.present?
        "replace"
      else
        "keep"
      end
    [
      fields.labelled_radio_button("Keep", :attachment_action, "keep", checked: keep_destroy_or_replace == "keep"),
      fields.labelled_radio_button("Remove", :attachment_action, "remove", checked: keep_destroy_or_replace == "destroy"),
      fields.labelled_radio_button("Replace", :attachment_action, "replace", checked: keep_destroy_or_replace == "replace"),
    ].join.html_safe
  end

  def consultation_response_form_data_fields(response_form_fields)
    object = response_form_fields.object.consultation_response_form_data
    if object.nil? && !response_form_fields.object.persisted?
      object = response_form_fields.object.build_consultation_response_form_data
    end

    response_form_fields.fields_for(:consultation_response_form_data, object) do |data_fields|
      contents = []
      contents << data_fields.label(:file, "Replacement") if response_form_fields.object.persisted?
      contents << data_fields.file_field(:file)
      if data_fields.object.file_cache.present?
        text = "#{File.basename(data_fields.object.file_cache)} already uploaded"
        text << " as replacement" if response_form_fields.object.persisted?
        contents << tag.span(text, class: "already_uploaded")
      end
      contents << data_fields.hidden_field(:file_cache)
      contents.join.html_safe
    end
  end

  def is_publication?(model_name)
    model_name == "publication"
  end

  def is_consultation?(model_name)
    model_name == "consultation"
  end

  def attachment_note(model_name)
    return "Attachments added to a #{model_name} will appear automatically." if is_publication?(model_name) || is_consultation?(model_name)

    "Attachments need to be referenced in the body markdown to appear in your document."
  end

  def attachments_tab_label(attachable)
    if attachable.attachments.count.positive?
      "Attachments <span class='badge'>#{attachable.attachments.count}</span>".html_safe
    else
      "Attachments"
    end
  end

  def attachments_nav_item_label(attachable)
    sanitize("Attachments #{tag.span(attachable.attachments.count, class: 'govuk-tag govuk-tag--grey') if attachable.attachments.count.positive?}")
  end
end
