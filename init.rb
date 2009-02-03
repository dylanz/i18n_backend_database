require 'i18n_backend_database'
require File.dirname(__FILE__) + '/lib/locale'
require File.dirname(__FILE__) + '/lib/translation'
require File.dirname(__FILE__) + '/lib/routing'
require File.dirname(__FILE__) + '/lib/locales_controller'
ActionController::Routing::RouteSet::Mapper.send(:include, I18n::BackendDatabase::Routing) 
