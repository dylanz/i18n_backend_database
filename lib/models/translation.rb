class Translation < ActiveRecord::Base
  belongs_to :locale
  
  named_scope :untranslated, :conditions => {:value => nil}

  def default_locale_value
    Locale.default_locale.translations.find_by_key(self.key).value rescue 'No default locale value'  
  end

end
