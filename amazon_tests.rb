require 'openssl'
require 'httparty'

secret_id = ENV['AMAZON_SECRET_ACCESS_KEY']

module AmazonProductAPI
  module Base

    def search_coffee_item(brand, item)
      query_params = {
        Operation: 'ItemSearch',
        SearchIndex: 'Books',
        ResponseGroup: 'Small,Images,AlternateVersions',
        Author: brand,
        Title: item
      }
      get(query_params)
    end

    def get(options)
      amazon_url = [url, query(options)].join('?')
      HTTParty.get(amazon_url)
    end

    def url
      "http://#{domain}/onca/xml"
    end

    def domain
      "webservices.amazon.com"
      # "webservices.amazon.#{LOCALES[@locale]}"
    end

    def query(options)
      add_defaults(options) # see default_options.rb
      add_timestamp(options)
      add_signature(options)
      HTTParty::HashConversions.to_params(options)
    end

    def add_timestamp(options)
      options[:Timestamp] = timestamp
    end

    def timestamp
      Time.now.utc.iso8601
    end

    def add_signature(options)
      options[:Signature] = signature(options)
      sort_hash! options   # see helpers.rb
    end

    # amazon signature docs
    # http://docs.aws.amazon.com/AWSECommerceService/latest/DG/rest-signature.html
    def signature(options)
      data = signature_data(options)
      sha256 = OpenSSL::Digest::SHA256.new
      digest = OpenSSL::HMAC.digest(sha256, secret_id, data)
      Base64.encode64(digest).strip
    end

    def signature_data(options)
      sort_hash! options   # see helpers.rb
      query = HTTParty::HashConversions.to_params(options)
      ['GET', domain, '/onca/xml', query].join("\n")
    end

  end
end
