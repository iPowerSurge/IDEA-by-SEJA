require "sinatra"
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
	property :woman, Boolean, :default => false
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

get "/men" do
	admin_only!
	@perfume = Perfume.all(pro: false)
	erb :perfumesmen
end

get "/women" do
	admin_only!
	@perfume = Perfume.all(pro: true)
	erb :perfumeswomen
end

get "/perfume/new" do
	admin_only!
	erb :new_perfume
end

post "/perfume/create" do
	admin_only!
	if(params["Name"] && params["Quantity"])
		v = Perfume.new
		v.name = params["Name"]
		v.qty = params["Quantity"]

		if params["Woman?"]
			if params["Woman?"] == "on"
				v.woman = true
			end
		end
		v.save
		return "Succesfully added #{v.name}"
	else
		return "Missing information"
	end
end
