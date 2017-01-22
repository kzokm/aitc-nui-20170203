# -*- coding: utf-8 -*-
require 'jawbone'
module Jawbone
  class Client
    define_method 'sleep_ticks' do |id|
      get_helper("sleeps/#{id}/ticks", {})
    end
  end
end

require 'sinatra'
require 'oauth2'

enable :sessions

def app_root
  "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{env['SCRIPT_NAME']}"
end

CLIENT_ID = ENV['CLIENT_ID']
APP_SECRET = ENV['APP_SECRET']

def oauth_client
  @client ||= OAuth2::Client.new(CLIENT_ID, APP_SECRET,
                                 :site => 'https://jawbone.com',
                                 :authorize_url => '/auth/oauth2/auth',
                                 :token_url => '/auth/oauth2/token')
end

get '/' do
  unless session[:oauth_token]
    %Q{<p><a href="/login">login</a>}
  else
    %Q{<p><a href="/logout">logout</a>
<p>your token : #{session[:oauth_token]}
<form action="/sleeps">
<input type="number" value="60" name="limit" style="width:4em" min="1" max="100">件
<input type="submit" value="Get Sleeps">
</form>}
  end
end

get '/login' do
  redirect oauth_client.auth_code.authorize_url(
    scope: 'sleep_read',
    redirect_uri: "#{app_root}/auth"
  )
end

get '/auth' do
  code = params['code']
  halt 400, 'code missing' unless code
  begin
    session[:oauth_token] = oauth_client.auth_code.get_token(code).token
    puts "TOKEN : #{session[:oauth_token]}"
  rescue => e
    STDERR.puts e.message
  end
  redirect '/'
end

get '/logout' do
  session.delete :oauth_token
  redirect '/'
end

get '/sleeps' do
  limit = params[:limit] || 30
  client = Jawbone::Client.new session[:oauth_token]
  sleeps = client.sleeps limit: limit
  halt 400, sleeps['meta']['message'] unless sleeps['meta']['code'] == 200

  items = sleeps['data']['items']
  items.each do |sleep|
    phases = client.sleep_ticks sleep['xid']
    sleep['phases'] = phases['data']['items']
  end

  if items.size > 0
    created = Time.at(items[items.size - 1]['time_created'])
    completed = Time.at(items[0]['time_completed'])
  else
    created = completed = Time.at(sleeps['meta']['time'])
  end

  content_type :json
  attachment "sleeps_#{sleeps['meta']['user_xid']}_#{created.strftime('%Y%m%d%H%M%S')}_#{completed.strftime('%Y%m%d%H%M%S')}.json"
  JSON.pretty_generate items
end
