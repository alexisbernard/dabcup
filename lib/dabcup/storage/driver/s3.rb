module Dabcup
  class Storage
    module Driver
      # Amazon S3
      class S3 < Base
        def initialize(config)
          super(config)
          require 'aws/s3'
          @bucket = config['bucket']
        rescue LoadError => ex
          raise Dabcup::Error.new("The library aws-s3 is missing. Get it via 'gem install aws-s3' and set RUBYOPT=rubygems.")
        end

        def protocol
          's3'
        end

        def put(local_path, remote_path)
          File.open(local_path) do |file|
            AWS::S3::S3Object.store(remote_path, file, @bucket)
          end
        end

        def get(remote_path, local_path)
          File.open(local_path, 'w') do |file|
            AWS::S3::S3Object.stream(remote_path, @bucket) do |stream|
              file.write(stream)
            end
          end
        end

        def list
          AWS::S3::Bucket.find(@bucket).objects.collect do |obj|
            Dump.new(:name => obj.key.to_s, :size => obj.size)
          end
        end

        def delete(file_name)
          AWS::S3::S3Object.delete(file_name, @bucket)
        end

        def connect
          return if AWS::S3::Base.connected?
          AWS::S3::Base.establish_connection!(:access_key_id => @login, :secret_access_key => @password)
          create_bucket
        end

        def disconnect
          AWS::S3::Base.disconnect!
        end

        def local?
          false
        end

        def create_bucket
          AWS::S3::Bucket.list.each do |bucket|
            return if bucket.name == @bucket
          end
          Dabcup::info("Create bucket s3://#{@bucket}")
        end
      end
    end
  end
end