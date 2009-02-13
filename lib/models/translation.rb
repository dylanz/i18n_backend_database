class Translation < ActiveRecord::Base
  belongs_to :locale
  validates_presence_of :key
  before_create :generate_hash_key
  after_update  :update_cache

  named_scope :untranslated, :conditions => {:value => nil}

  def default_locale_value(rescue_value='No default locale value')
    Locale.default_locale.translations.find_by_key_and_pluralization_index(self.key, self.pluralization_index).value rescue rescue_value
  end

  def value_or_default(key)
    self.value || self.default_locale_value(key)
  end

  def self.hk(key)
    Base64.encode64(Digest::MD5.hexdigest(key))
  end

  protected
    def generate_hash_key
      self.key = Translation.hk(key)
    end
    
    def update_cache
      I18n.backend.cache_store.write("#{self.locale.code}:#{self.key}:#{self.pluralization_index}", self.value)
    end
end
