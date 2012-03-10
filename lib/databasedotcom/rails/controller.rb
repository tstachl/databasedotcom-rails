module Databasedotcom
  module Rails
    module Controller
      module ClassMethods
        def dbdc_client
          unless @dbdc_client
            if FileTest.exists?(File.join(::Rails.root, 'config', 'databasedotcom.yml'))
              config = YAML.load_file(File.join(::Rails.root, 'config', 'databasedotcom.yml'))
              config = config.has_key?(::Rails.env) ? config[::Rails.env] : config
            end
            config ||= {}
            
            @dbdc_client = Databasedotcom::Client.new(config)
            if config['authtype'] == 'password'
              username = config["username"]
              password = config["password"]
              @dbdc_client.authenticate(:username => username, :password => password)
            elsif config['authtype'] == 'token'
              token = config['token']
              instance_url = config['instance_url']
              @dbdc_client.authenticate(:token => token, :instance_url => instance_url)
            elsif ENV.has_key?('DATABASEDOTCOM_USERNAME') and ENV.has_key?('DATABASEDOTCOM_PASSWORD')
              @dbdc_client.authenticate(:username => ENV['DATABASEDOTCOM_USERNAME'], :password => ENV['DATABASEDOTCOM_PASSWORD'])
            end
          end

          @dbdc_client
        end
        
        def dbdc_client=(client)
          @dbdc_client = client
        end

        def sobject_types
          unless @sobject_types
            @sobject_types = dbdc_client.list_sobjects
          end

          @sobject_types
        end

        def const_missing(sym)
          if sobject_types.include?(sym.to_s)
            dbdc_client.materialize(sym.to_s)
          else
            super
          end
        end
      end
      
      module InstanceMethods
        def dbdc_client
          self.class.dbdc_client
        end

        def sobject_types
          self.class.sobject_types
        end
      end
      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
      end
    end
  end
end
