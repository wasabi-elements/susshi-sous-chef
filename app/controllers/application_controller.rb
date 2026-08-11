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

class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  protect_from_forgery prepend: true

  before_action :authenticate_user!
  before_action :set_box_css_class

  helper_method :current_user, :user_logged_in?

  layout "box"

  def authenticate_user!
    if session["omniauth.info"].blank?
      redirect_to new_session_path

      reset_session
    else
      if session["expires"] < Time.now
        redirect_to redirect_logout_path, allow_other_host: true

        reset_session
      end
    end
  end

  def chef_api
    @chef_api ||= Chef::Api.new(current_user)
  end

  def current_user
    unless session["omniauth.info"].blank?
      RequestStore.store[:current_user] ||= User.new(session["omniauth.info"])
    end

    RequestStore.store[:current_user]
  end

  def user_logged_in?
    !!current_user
  end

  def set_box_css_class
    @box_css_class = controller_name == "sessions" ? :small : :large
  end

  def redirect_logout_path
    if session["omniauth.info"]
      discovery = OpenIDConnect::Discovery::Provider::Config.discover!(session["omniauth.info"]["iss"])
      discovery&.try(:end_session_endpoint) || new_session_path
    else
      new_session_path
    end
  rescue StandardError
    new_session_path
  end
end
