require 'addressable/uri'
require 'forwardable'

module Dabcup
  class Storage
    module Driver
      def self.build(url)
        if url.include?('file://')
          Dabcup::Storage::Driver::Local.new(url)
        elsif url.include?('ssh://')
          Dabcup::Storage::Driver::SFTP.new(url)
        elsif url.include?('ftp://')
          Dabcup::Storage::Driver::FTP.new(url)
        elsif url.include?('s3://')
          Dabcup::Storage::Driver::S3.new(url)
        else
          raise "No driver found for '#{url}'"
        end
      end

      class Base
        attr_reader :uri
        extend Forwardable
        def_delegators :@uri, :host, :port, :user, :password, :path
        
        def initialize(uri)
          @uri = Addressable::URI.parse(uri)
        end

        def exclude?(name)
          ['.' '..'].include?(name)
        end

        ################################
        ##### Methods to implement #####
        ################################

        def disconnect
          raise NotImplementedError
        end

        def put(local_path, remote_name)
          raise NotImplementedError
        end

        def get(remote_name, local_path)
          raise NotImplementedError
        end

        def list
          raise NotImplementedError
        end

        def delete(dump_name)
          raise NotImplementedError
        end

        def protocol
          raise NotImplementedError
        end

        def local?
          raise NotImplementedError
        end
      end
    end
  end
end
