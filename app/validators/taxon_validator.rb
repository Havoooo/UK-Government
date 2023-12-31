class TaxonValidator < ActiveModel::Validator
  def validate(edition)
    if missing_taxons?(edition)
      edition.errors.add(
        :base,
        "This document has not been published. You need to add a topic before publishing.".html_safe,
      )
    end
  end

private

  def missing_taxons?(edition)
    !edition.has_been_tagged?
  end
end
