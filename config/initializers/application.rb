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

SOUS_CHEF_CONFIG ||= {}
SOUS_CHEF_CONFIG["config_paths"] = %W[/config #{Rails.root.join("config")}]

if %w[development production].include? Rails.env
  path = SOUS_CHEF_CONFIG["config_paths"].find { |dir| File.exist? File.join(dir, "application.yml") }

  if path.nil?
    abort "suSSHi Sous-Chef configuration missing!"
  else
    SOUS_CHEF_CONFIG.merge!(YAML.safe_load_file("#{path}/application.yml", aliases: true))

    if SOUS_CHEF_CONFIG.dig("chef").is_a?(Hash)
      %w[api_endpoint api_application api_token].each do |key|
        abort "suSSHi Chef Api configuration '#{key}' not found!" if SOUS_CHEF_CONFIG.dig("chef", key).blank?
      end
    else
      abort "suSSHi Chef API configuration missing!"
    end

    unless SOUS_CHEF_CONFIG.dig("omniauth", "providers").is_a?(Array)
      abort "Omniauth provider configuration missing!"
    end
  end
end
