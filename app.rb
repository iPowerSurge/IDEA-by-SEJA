require "sinatra"
require "sinatra/flash"
require_relative "authentication.rb"
require "data_mapper"

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class Perfume
	include DataMapper::Resource

	property :id, Serial
	property :name, Text
	property :qty, Text
end

DataMapper.finalize
User.auto_upgrade!
Perfume.auto_upgrade!

#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
	u = User.new
	u.email = "admin@admin.com"
	u.password = "admin"
	u.administrator = true
	u.save
end

def make_cart
	session[:cart]={}
	redirect "/perfumes"
end

def add_to_cart(pid)
	make_cart if !session.has_key?(:cart)

	if(session[:cart][pid])
		session[:cart][pid] += 1
	else
		session[:cart][pid] = 1
	end
end

def remove_from_cart(pid)
	make_cart if !session[:cart]
	if(session[:cart][pid] != nil && session[:cart][pid] > 1)
		session[:cart][pid] = session[:cart][pid] - 1
	else
		session[:cart].delete(pid)
	end
end

def show_cart
	@perfume.each do |cart, pid|
		puts "#{cart}:#{pid}"
	end
end
#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do
	erb :index
end

get "/perfumes" do
	admin_only!
	@perfume = Perfume.all
	erb :perfumes
end


get "/perfume/new" do
	admin_only!
	erb :new_perfume
end

post "/perfume/create" do
	admin_only!
	if(params["Name"])
		v = Perfume.new
		v.name = params["Name"]
		v.save
		flash[:success] = "Succesfully added #{v.name}."
		redirect "/"
	else
		flash[:error] = "Error: Missing information."
		redirect "/"
	end
end

get "/perfume/delete/:pid" do
	pid = params[:pid]
	p = Perfume.get(pid)
	if p
		flash[:success] = "Successfully deleted #{p.name}"
		p.destroy
		session[:cart].delete(pid)	
		redirect "/perfumes"
	else
		flash[:error] = "Could not find the product."
		redirect "/perfumes"
	end
end

get "/add_to_cart/:pid" do
	pid = params[:pid].to_i
	p = Perfume.get(pid)
	add_to_cart(pid)
	flash[:success] = "#{p.name} successfully added to cart."
	redirect "/perfumes"
end

get "/remove_from_cart/:pid" do
	pid = params[:pid].to_i
	p = Perfume.get(pid)
	remove_from_cart(pid)
	flash[:success] = "#{p.name} successfully removed cart."
	redirect "/perfumes"
end

get "/cart" do
	@cart = session[:cart]
	erb :cart
end
