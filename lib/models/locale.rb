class Locale < ActiveRecord::Base
  validates_presence_of :code
  validates_uniqueness_of :code

  has_many :translations, :dependent => :destroy

  @@default_locale = nil

  def self.default_locale
    @@default_locale ||= self.find(:first, :conditions => {:code => I18n.default_locale.to_s})
  end

  def self.reset_default_locale
    @@default_locale = nil
  end

  def translation_from_key(key)
    self.translations.find(:first, :conditions => {:key => key})
  end

  def create_translation(key, value)
    conditions = {:key => key}

    # set the key as the value if we're using the default locale
    conditions.merge!({:value => value}) if (self.code == I18n.default_locale.to_s)
    translation = self.translations.create(conditions)

    # hackity hack.  bug #922 maybe?
    self.connection.commit_db_transaction unless RAILS_ENV['test']
    translation
  end
  
  def find_translation_or_copy_from_default_locale(key)
    self.translations.find_by_key(key) || copy_from_default(key)
  end
  
  def copy_from_default(key)
    create_translation(key, key) if !self.default_locale? && Locale.default_locale.has_translation?(key)
  end
  
  def has_translation?(key)
    self.translations.exists?(:key => key)
  end

  def self.available_locales
    all.map(&:code).map(&:to_sym)
  end
  
  def default_locale?
    self == Locale.default_locale
  end

  def to_param
    self.code
  end
end
