module I18n
  module Backend
    module Database
      class Cache
        include Singleton

        attr_reader :cache_size

        def initialize
          @cache = {}
          @cache_size = 0
        end
      end
    end
  end
end
