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

# https://github.com/omniauth/omniauth#rack_csrf
# OmniAuth::AuthenticityTokenProtection.default_options(key: "csrf.token", authenticity_param: "_csrf")

unless defined?(Patches::RedirectUriPatch)
  module Patches
    module RedirectUriPatch
      def redirect_uri
        if params["redirect_uri"].blank? && client_options.redirect_uri.blank?
          return request.base_url + "/auth/#{name}/callback"
        end

        super
      end
    end
  end
end

OmniAuth::Strategies::OpenIDConnect.prepend(Patches::RedirectUriPatch)

OmniAuth.config.on_failure = proc do |env|
  SessionsController.action(:omniauth_failure).call(env)
end

Rails.application.config.middleware.use OmniAuth::Builder do
  (SOUS_CHEF_CONFIG.dig("omniauth", "providers") || []).each do |config|
    provider config["provider"], **(config.except("provider"))
  end
end
