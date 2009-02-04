class Locale < ActiveRecord::Base
  validates_presence_of :code
  validates_uniqueness_of :code

  has_many :translations, :dependent => :destroy

  @@default_locale = nil

  def self.default_locale
    @@default_locale ||= self.find(:first, :conditions => {:code => I18n.default_locale.to_s})
  end

  # find the translation, or create one if it doesn't exist
  def find_or_create_translation(key, value, options = {})
    conditions  = {:key => key, :pluralization_index => (options[:pluralization_index] || 1)}
    translation = self.translations.find(:first, :conditions => conditions)
    return translation if translation

    # set the key as the value if we're using the current locale
    conditions.merge!({:value => value}) if (self.code == I18n.default_locale.to_s)
    self.translations.create(conditions)
  end

  def self.available_locales
    all.map(&:code).map(&:to_sym)
  end

  def to_param
    self.code
  end
end
