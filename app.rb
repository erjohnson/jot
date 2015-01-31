require 'bundler'
require 'bundler/setup'

# Reloads our app, useful during development
require 'sinatra/reloader'

# Have Bundler require default Gems
Bundler.require

Dotenv.load

helpers do
  # Connect to Orchestrate, expose client object to routes
  def client
    @client ||= Orchestrate::Client.new(ENV['ORC_API_KEY'])
  end
end

# Root
get '/' do
  @list = client.list(:documents).results
  if @list.empty?
    erb :no_docs
  else
    @list
    erb :index
  end
end

# New document form
get '/new' do
  erb :new
end

post '/new' do
  @doc_id = params[:title].downcase.chomp.gsub(' ', '-')
  @new_doc = { title: params[:title], content: '' }
  @res = client.put(:documents, @doc_id, @new_doc)
  if @res.success?
    redirect to("/document/#{@doc_id}")
  end
end

get '/document/:id' do
  @res = client.get(:documents, params[:id])
  if @res.success?
    @title = @res.body['title']
    @content = @res.body['content']
    @id = params[:id]
  end
  erb :show
end

put '/document/:id' do
  @doc = { title: params[:title], content: params[:content] }
  @res = client.put(:documents, params[:id], @doc)
  status 201 if @res.success?
end

get '/undo/:id' do
  options = { limit: 1, offset: 1, values: true }
  @prev_ref = client.list_refs(:documents, params[:id], options)
  @prev_ref.on_complete do
    @prev_val = @prev_ref.results.first['value']
  end
  @res = client.put(:documents, params[:id], @prev_val)
  if @res.success?
    redirect to("/document/#{params[:id]}")
  end
end
