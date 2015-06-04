require 'fog'
require 'sinatra/base'
require 'sinatra/flash'

module Console
  class Ui < Sinatra::Base
		enable :sessions
		register Sinatra::Flash


		get '/' do
			erb :login
		end	

		post '/' do

			
			login_params = {
  			:vcloud_director_username => "#{params['user_id']}@#{params['org_id']}",
  			:vcloud_director_password => params['password'],
  			:vcloud_director_host => 'api.vcd.portal.skyscapecloud.com',
  			:vcloud_director_show_progress => false, # task progress bar on/off
			}

			begin
				session['vcd']=nil
	    	session['vcd'] = Vcloud.new(login_params)
				flash[:notice] = "Logged In Succesfully"
				redirect '/ui'
			rescue => e
				flash[:error] = "Unable To Login: #{e.message}"
			  redirect to('/')
			end
#				erb :ui, :locals => {'gateways' => @vdc.all_edges}

		end

		get '/ui' do
			vcd = session['vcd']
			if vcd && vcd.logged_in?
				erb :ui, :locals => {'gateways' => vcd.all_edges}
			else
				redirect '/'
			end
			
		end
	end

	class Vcloud
    def initialize(conn)
			@vcd = connect(conn)
		end

		def connect(params)
			vcd = Fog::Compute::VcloudDirector.new(params)
			vcd.organizations.first
			vcd
		end

		def all_edges
			org = @vcd.organizations.first
		  gateways = []	

			org.vdcs.map do |vdc| 
			  gw_record = get_edge_gateways(vdc.id).body[:EdgeGatewayRecord]
				gateways.push(
					{
						:href => gw_record[:href],
						:name => gw_record[:name],
						:vdc => vdc.name
					})
			end
			
			gateways		
			
		end

		def get_edge_gateways(vdc_id)
          response = @vcd.request(
            :expects    => 200,
            :idempotent => true,
            :method     => 'GET',
            :parser     => Fog::ToHashDocument.new,
            :path       => "admin/vdc/#{vdc_id}/edgeGateways"
          )
          response
    end


		def logged_in?
			begin 
				@vcd.organizations.first
				true
			rescue => e
				false
			end	
		end

	end
end
