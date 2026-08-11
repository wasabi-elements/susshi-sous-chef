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

module ApplicationHelper
  def application_name
    "suSSHi Sous Chef"
  end

  def identity_providers
    @identity_providers ||= (SOUS_CHEF_CONFIG["omniauth"]["providers"] || []).collect do |provider|
      {
        label: (provider["label"] || provider["provider"]),
        path: "/auth/#{provider["name"] || provider["provider"]}"
      }
    end
  end

  def identity_provider_forms
    content_tag :div do
      css_class = [ "loader" ]
      css_class << "hide" if identity_providers.many?
      concat(content_tag(:div, nil, class: css_class.join(" ")))

      css_class = [ "providers" ]
      css_class << "hide" if identity_providers.one?
      concat(
        content_tag(:div, class: css_class.join(" ")) do
          identity_providers.each do |provider|
            concat(identity_provider_form(provider))
          end
        end
      )
    end
  end

  def identity_provider_form(provider)
    form_tag provider[:path], class: :provider do
      content_tag :button, type: :submit do
        content_tag :span, provider[:label]
      end
    end
  end

  def copyright
    "Copyright &copy 2017-#{Time.zone.now.year} by Wasabi Elements GmbH".html_safe
  end

  def with_layout(layout = "application", &block)
    render inline: capture(&block), layout: "layouts/#{layout}"
  end

  def ensure_sentence_punctuation(text)
    return text if text.blank?

    text.match?(/[.!?]\z/) ? text : "#{text}."
  end
end
