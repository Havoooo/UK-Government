class GenericEdition < Edition
  include Attachable

  class << self
    attr_accessor :translatable
  end
  def translatable?
    self.class.translatable
  end
end
