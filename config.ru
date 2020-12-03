require 'rubygems'
require 'bundler/setup'
require 'rack'

require_relative './server/tls_odkbuild'
require_relative './server/warden_odkbuild'
require_relative './server/model/connection_manager'
require_relative './server/config_manager'
require_relative './server/asset_manager'
require_relative './server/odkbuild_server'

# load configuration files
ConfigManager.load
AssetManager.load

# middleware
use Rack::CommonLogger

if ConfigManager['cookie_ssl_only']
  use Build::TLS
end

use Rack::Session::Cookie,
  :secret => ConfigManager['cookie_secret']

use ConnectionManager

use Warden::Manager do |manager|
  manager.default_strategies :odkbuild
  manager.failure_app = OdkBuild
  manager.serialize_into_session do |user|
    user.nil? ? nil : user.username
  end
  manager.serialize_from_session do |id|
    id.nil? ? nil : (User.find id)
  end
end

use Rack::Static, :urls => [ '/stylesheets', '/javascripts', '/images' ], :root => 'public'

# app
run OdkBuild

