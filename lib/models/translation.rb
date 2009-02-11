class Translation < ActiveRecord::Base
  belongs_to :locale
  validates_presence_of :key

  named_scope :untranslated, :conditions => {:value => nil}

  def default_locale_value
    Locale.default_locale.translations.find_by_key(self.key).value rescue self.key 
  end
  
  def value_or_default
    self.value || self.default_locale_value
  end

end
