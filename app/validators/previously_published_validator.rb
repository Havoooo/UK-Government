class PreviouslyPublishedValidator < ActiveModel::Validator
  def validate(record)
    record.has_previously_published_error = false

    if record.previously_published.nil?
      record.errors.add(:previously_published, "You must specify whether the document has been published before")
      record.has_previously_published_error = true
    elsif (record.previously_published || record.published_major_version) && record.first_published_at.blank?
      record.errors.add(:first_published_at, "can't be blank")
    end
  end
end
