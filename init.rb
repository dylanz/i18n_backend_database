require 'i18n_backend_database'
require File.dirname(__FILE__) + '/lib/routing'
require File.dirname(__FILE__) + '/lib/locales_controller'
require File.dirname(__FILE__) + '/lib/i18n_backend_database/locale'
require File.dirname(__FILE__) + '/lib/i18n_backend_database/translation'
ActionController::Routing::RouteSet::Mapper.send(:include, I18n::BackendDatabase::Routing) 
