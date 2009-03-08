class Translation < ActiveRecord::Base
  belongs_to :locale
  validates_presence_of :key
  before_create :generate_hash_key
  after_update  :update_cache

  named_scope :untranslated, :conditions => {:value => nil}
  named_scope :translated,   :conditions => "value IS NOT NULL"

  attr_accessor :ignore_hash_key
  
  def default_locale_value(rescue_value='No default locale value')
    begin
      Locale.default_locale.translations.find_by_key_and_pluralization_index(self.key, self.pluralization_index).value
    rescue
      rescue_value
    end
  end

  def value_or_default(key)
    self.value || self.default_locale_value(key)
  end

  # create hash key
  def self.hk(key)
    Base64.encode64(Digest::MD5.hexdigest(key))
  end

  # create cache key
  def self.ck(locale, key, pluralization_index, hash=true)
    key = self.hk(key) if hash
    "#{locale.code}:#{key}:#{pluralization_index}"
  end

  protected
    def generate_hash_key
      self.key = Translation.hk(key) unless ignore_hash_key
    end

    def update_cache
      new_cache_key = Translation.ck(self.locale, self.key, self.pluralization_index, false)
      I18n.backend.cache_store.write(new_cache_key, self.value)
    end
end
