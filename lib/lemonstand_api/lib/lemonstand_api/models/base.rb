require 'ostruct'
require 'json'
require 'open-uri'
require 'net/http'
# require 'uri'

module LemonstandAPI
  class Base

    def initialize(store, access_token: nil, domain: nil, resource_name: nil)
      domain       ||= store.domain
      access_token ||= store.access_token
      @site = "http://#{domain}/api/v2/#{resource_name.to_s}"
      @auth = "Bearer #{access_token}"
    end

    def all(embed: [])
      uri = open_remote_file(embed: embed)
      return unless uri.present?

      items = safe_json_read(uri)
      return unless items.present?

      items['data'].map{|p| OpenStruct.new(p)}
    end

    def find(id, embed: [])
      uri = open_remote_file(id: id, embed: embed)
      return unless uri.present?

      item = safe_json_read(uri)
      return unless item.present?

      OpenStruct.new(item['data'])
    end

    def create(**args)
      url = URI.parse(@site)
      req = Net::HTTP::Post.new(url.path)
      req.add_field('Authorization', @auth)
      req.add_field('Content-Type', 'application/json')
      req.body = args.to_json

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == "https")
      res = http.request(req)

      if (res.code == '307' || res.code == '301') && res.get_fields('Location').present?
        @site = res.get_fields('Location')[0]
        res = create(args)
      end
      res
    end

    def open_remote_file(id: nil, embed: [])
      begin
        uri = open("#{@site}#{id.present? ? "/#{id}" : "s"}?embed=#{embed.join(',')}", "Authorization" => @auth)
      rescue OpenURI::HTTPError, RuntimeError, SocketError => e
        puts e
        return nil
      end
      uri
    end

    def safe_json_read(uri)
      begin
        item = JSON.parse(uri.read)
      rescue JSON::ParserError => e
        puts e
        return nil
      end
      item
    end

  end
end
