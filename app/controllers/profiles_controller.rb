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

class ProfilesController < ApplicationController
  skip_before_action :authenticate_user!, unless: :profile_enabled?

  before_action :ensure_profile_enabled!, only: %i[create_susshi_user_key delete_susshi_user_key]
  before_action :susshi_user_login, if: :profile_enabled?

  def edit
    render :disabled unless profile_enabled?
  end

  def create_susshi_user_key
    if chef_api.connection?
      title = "Uploaded by #{susshi_user_login["username"]} on #{Time.now.strftime("%B %d, %Y")} at #{Time.now.strftime("%H:%M:%S")}"
      payload = {
        title:,
        public_blob: params[:public_blob],
        username: susshi_user_login["username"]
      }

      chef_api.create_susshi_user_key(payload)
      @response = chef_api.chef_response

      if chef_api.response&.code == 200
        redirect_to profiles_edit_path, notice: t("controllers.profiles.create_susshi_user_key.notice.success")
      else
        render :edit
      end
    else
      render :edit
    end
  end

  def delete_susshi_user_key
    if chef_api.connection?
      chef_api.delete_susshi_user_key(params[:id])
      @response = chef_api.chef_response

      if chef_api.response&.code == 204
        redirect_to profiles_edit_path, notice: t("controllers.profiles.delete_susshi_user_key.notice.success")
      else
        render :edit
      end
    else
      render :edit
    end
  end

  private

  def ensure_profile_enabled!
    head :forbidden unless profile_enabled?
  end

  def profile_enabled?
    %w[true 1].include?(ENV["SOUS_CHEF_ENABLE_PROFILE"].to_s.downcase)
  end

  def set_box_css_class
    @box_css_class = profile_enabled? ? :large : :small
  end

  def susshi_user_login
    if chef_api.connection? && chef_api.susshi_user_login?
      @susshi_user_login ||= chef_api.susshi_user_login
    end
  end
end
