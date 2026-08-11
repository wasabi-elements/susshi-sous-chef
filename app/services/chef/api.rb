# Copyright (C) 2026 Wasabi Elements GmbH
#
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

module Chef
  class Api
    attr_accessor :user

    attr_reader :error, :response, :chef_response

    def initialize(user = nil)
      self.user = user
    end

    def connection?
      !!version
    end

    def create_susshi_user_key(payload = {})
      payload = payload.merge(activate: true).to_json

      response_codes = [ 204, 404, 422 ]
      request("/api/v1/config/susshi_user_keys", payload:, method: :post, response_codes:)
    end

    def delete_susshi_user_key(id)
      payload = { activate: true }.to_json

      response_codes = [ 204, 404, 422 ]
      request("/api/v1/config/susshi_user_keys/#{id}", method: :delete, payload:, response_codes:)
    end

    def logout(jwt = {})
      payload = { jwt: }.to_json
      response_codes = [ 200, 422 ]

      request("/api/v1/operations/oidc/logout", method: :post, payload:, response_codes:)
    end

    def susshi_user_login
      return if user.blank? || user.uid.blank?

      @susshi_user_login ||= request("/api/v1/config/susshi_users/logins/#{user.uid}", method: :get)
    end

    def susshi_user_login?
      !!susshi_user_login
    end

    def validate(secret, jwt = {})
      payload = { secret:, jwt: }.to_json
      response_codes = [ 200, 404, 410, 422 ]

      request("/api/v1/operations/oidc/validate", method: :post, payload:, response_codes:)
    end

    def version
      @version ||= request("/api/v1/operations/version", method: :get)
    end

    private

    def request_defaults
      {
        headers: {
          "Api-Application" => SOUS_CHEF_CONFIG.dig("chef", "api_application"),
          "Api-Token" => SOUS_CHEF_CONFIG.dig("chef", "api_token")
        },
        timeout: (SOUS_CHEF_CONFIG.dig("chef", "timeout") || 5).to_i,
        verify_ssl: SOUS_CHEF_CONFIG.dig("chef", "ssl_verify") != false
      }
    end

    def request(path, **kwargs)
      options = request_defaults
      response_codes = kwargs.delete(:response_codes) || 200

      options.merge!(url: "#{SOUS_CHEF_CONFIG.dig("chef", "api_endpoint")}/#{path.gsub(/^\//, "")}")
      options.merge!(kwargs.slice(:method, :payload))
      options[:headers].merge!(kwargs[:headers] || {})

      if json?(options[:payload])
        options[:headers].merge!("Content-Type" => "application/json")
      end

      RestClient::Request.execute(**options) do |response, request, result, &block|
        @chef_response = Chef::Response.new(response)

        case (@response = response).code
        when *response_codes
          JSON.parse(response.body)
        else
          false
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Chef::Api - malformed JSON response: #{(@error = e).inspect}")

        false
      end
    rescue StandardError => e
      Rails.logger.error("Chef::Api - #{(@error = e).inspect}")

      false
    end

    def json?(json)
      return false if json.blank?

      JSON.parse(json)
      true
    rescue JSON::ParserError
      false
    end
  end
end
