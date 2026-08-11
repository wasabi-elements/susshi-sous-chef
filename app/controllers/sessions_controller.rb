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

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :back_channel_logout_callback, :destroy, :login_callback, :new, :omniauth_failure ]
  skip_before_action :verify_authenticity_token, only: [ :omniauth_failure ]

  DEFAULT_SESSION_EXPIRATION_TIMEOUT = 300

  def back_channel_logout_callback
    if params.key?(:logout_token)
      logout_token = params[:logout_token]
      unverified_token = JSON::JWT.decode(logout_token, :skip_verification)

      discovery = OpenIDConnect::Discovery::Provider::Config.discover!(unverified_token["iss"])
      verified_token = OpenIDConnect::ResponseObject::IdToken.decode(logout_token, discovery.jwks)

      chef_api.logout(verified_token.raw_attributes.to_hash.slice(*%w[iss aud sid sub]))
      head chef_api.response&.code
    else
      head :bad_request
    end
  rescue StandardError => e
    Rails.logger.error "Back-channel logout error: #{e.message}"

    head :bad_request
  end

  def destroy
    redirect_to redirect_logout_path, allow_other_host: true

    reset_session
  end

  def login_callback
    if request.env.key?("omniauth.auth")
      auth_info = request.env["omniauth.auth"]

      if (raw_info = auth_info.dig("extra", "raw_info")).blank?
        reset_session

        redirect_to new_session_path
      else
        raw_info.merge!(uid: auth_info["uid"])
        session["omniauth.info"] = raw_info.slice(*%w[iss aud name sid sub uid])
        session["expires"] = session_expiration_timeout.seconds.from_now

        if session.key?("susshi.auth.secret")
          redirect_to session_validate_path
        else
          redirect_to root_path
        end
      end
    else
      reset_session

      redirect_to new_session_path
    end
  end

  def validate
    if chef_api.connection?
      chef_api.validate(
        session.delete("susshi.auth.secret"),
        session["omniauth.info"].slice(*%w[iss aud sid sub uid])
      )

      case chef_api.response&.code
      when 200
        render "sessions/authorize/success"
      when 404
        render "sessions/authorize/errors/not_found"
      when 410
        render "sessions/authorize/errors/gone"
      else
        render "sessions/authorize/errors/failure"
      end
    else
      render "sessions/authorize/errors/api"
    end
  end

  def new
    if params.key?(:secret)
      session["susshi.auth.secret"] = params[:secret]

      render "sessions/authorize/new"
    else
      render "sessions/new"
    end
  end

  def omniauth_failure
    Rails.logger.error "OmniAuth authentication failure: #{request.env["omniauth.error.type"]}"

    render "sessions/authorize/errors/login"
  end

  private

  def session_expiration_timeout
    timeout = ENV["SOUS_CHEF_SESSION_EXPIRATION_TIMEOUT"]
    timeout = timeout =~ /\A\d+\z/ ? timeout.to_i : nil

    (timeout.blank? || timeout.zero?) ? DEFAULT_SESSION_EXPIRATION_TIMEOUT : timeout
  end
end
