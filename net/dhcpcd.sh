# Copyright 2007 Roy Marples
# All rights reserved

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

dhcpcd_depend() {
	after interface
	program start /sbin/dhcpcd /usr/local/sbin/dhcpcd
	provide dhcp

	# We prefer dhcpcd over the others
	after dhclient pump udhcpc
}

_config_vars="$_config_vars dhcp dhcpcd"

dhcpcd_start() {
	local args= opt= opts= pidfile="/var/run/dhcpcd-${IFACE}.pid"

	eval args=\$dhcpcd_${IFVAR}

	# Get our options
	eval opts=\$dhcp_${IFVAR}
	[ -z "${opts}" ] && opts=${dhcp}

	# Map some generic options to dhcpcd
	for opt in ${opts}; do
		case "${opt}" in
			nodns) args="${args} -R";;
			nontp) args="${args} -N";;
			nonis) args="${args} -Y";;
			nogateway) args="${args} -G";;
			nosendhost) args="${args} -h ''";
		esac
	done

	# Add our route metric
	[ "${metric:-0}" != "0" ] && args="${args} -m ${metric}"

	# Bring up DHCP for this interface
	ebegin "Running dhcpcd"

	eval dhcpcd "${args}" "${IFACE}"
	eend $? || return 1

	_show_address
	return 0
}

dhcpcd_stop() {
	local pidfile="/var/run/dhcpcd-${IFACE}.pid" opts= sig=SIGTERM
	[ ! -f "${pidfile}" ] && return 0

	ebegin "Stopping dhcpcd on ${IFACE}"
	eval opts=\$dhcp_${IFVAR}
	[ -z "${opts}" ] && opts=${dhcp}
	case " ${opts} " in
		*" release "*) sig=SIGHUP;;
	esac
	start-stop-daemon --stop --quiet --signal "${sig}" --pidfile "${pidfile}"
	eend $?
}

# vim: set ts=4 :
