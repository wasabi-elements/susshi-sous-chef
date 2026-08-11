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

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "profiles#edit"

  # Sessions
  get "/login", to: "sessions#new", as: :new_session
  get "/logout", to: "sessions#destroy", as: :destroy_session

  # Callbacks
  get "/auth/:provider/callback", to: "sessions#login_callback"
  post "/back-channel-logout", to: "sessions#back_channel_logout_callback"

  # Profiles
  get "/profiles/edit", to: "profiles#edit"
  post "/profiles/susshi_user_key", to: "profiles#create_susshi_user_key"
  delete "/profiles/susshi_user_key", to: "profiles#delete_susshi_user_key"

  # Validate SSH Session
  get "/session/validate", to: "sessions#validate"

  # Authorize SSH Session
  match "/:secret", via: [ :get ], to: "sessions#new", constraints: { secret: /[a-zA-Z0-9]{32}/ }
  match "/*/:secret", via: [ :get ], to: "sessions#new", constraints: { secret: /[a-zA-Z0-9]{32}/ }
end
