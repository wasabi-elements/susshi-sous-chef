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

class User
  attr_accessor :auth_info

  def initialize(auth_info)
    raise StandardError, t("models.user.auth_info_missing") if auth_info.blank?

    self.auth_info = auth_info
  end

  def method_missing(method, *args)
    if auth_info.keys.include?(method.to_s)
      auth_info[method.to_s]
    else
      super
    end
  end
end
