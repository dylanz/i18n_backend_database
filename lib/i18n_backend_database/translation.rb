module I18n
  class Translation < ActiveRecord::Base
    belongs_to :locale
  end
end
