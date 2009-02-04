map.resources :locales, :has_many => :translations
map.untranslated '/untranslated', :controller => 'translations', :action => 'untranslated'