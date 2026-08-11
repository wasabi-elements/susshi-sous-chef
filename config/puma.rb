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

# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.
#
# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
# should only set this value when you want to run 2 or more workers. The
# default is already 1. You can set it to `auto` to automatically start a worker
# for each available processor.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments.
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

puma_port = ENV.fetch("PUMA_PORT", 3000)
puma_ip4_port = ENV.fetch("PUMA_IPV4_PORT", puma_port)
puma_ip6_port = ENV.fetch("PUMA_IPV6_PORT", puma_port)

path = SOUS_CHEF_CONFIG["config_paths"].find do |path|
  %w[server.crt server.key].all? { |f| File.exist?(File.join(path, "ssl", f)) }
end

if path.is_a?(String)
  options = {
    cert: File.join(path, "ssl", "server.crt"),
    key: File.join(path, "ssl", "server.key")
  }

  addr_list = Socket.ip_address_list.reject(&:ipv6_linklocal?)
  ipv6_available = addr_list.any? { |a| a.afamily == Socket::AF_INET6 }
  ipv4_available = addr_list.any? { |a| a.afamily == Socket::AF_INET }

  if ipv4_available && ipv6_available
    if ENV["SYSCTL_BINDV6ONLY"] == "1"
      ssl_bind ENV.fetch("PUMA_IPV4_ADDRESS", "0.0.0.0"), puma_ip4_port, options
      ssl_bind ENV.fetch("PUMA_IPV6_ADDRESS", "[::]"), puma_ip6_port, options
    else
      ssl_bind ENV.fetch("PUMA_IPV6_ADDRESS", "[::]"), puma_port, options
    end
  elsif ipv6_available
    ssl_bind ENV.fetch("PUMA_IPV6_ADDRESS", "[::]"), puma_ip6_port, options
  elsif ipv4_available
    ssl_bind ENV.fetch("PUMA_IPV4_ADDRESS", "0.0.0.0"), puma_ip4_port, options
  end
else
  port puma_port
end

bind "unix:///tmp/puma.sock"
