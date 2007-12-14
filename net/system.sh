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

_config_vars="$_config_vars dns_servers dns_domain dns_search"
_config_vars="$_config_vars dns_sortlist dns_options"
_config_vars="$_config_vars ntp_servers nis_servers nis_domain"

system_depend() {
	after interface
	before dhcp
}

_system_dns() {
	local servers= domain= search= sortlist= options= x=

	eval servers=\$dns_servers_${IFVAR}
	[ -z "${servers}" ] && servers=${dns_servers}

	eval domain=\$dns_domain_${IFVAR}
	[ -z "${domain}" ] && domain=${dns_domain}

	eval search=\$dns_search_${IFVAR}
	[ -z "${search}" ] && search=${dns_search}

	eval sortlist=\$dns_sortlist_${IFVAR}
	[ -z "${sortlist}" ] && sortlist=${dns_sortlist}

	eval options=\$dns_options_${IFVAR}
	[ -z "${options}" ] && options=${dns_options}

	[ -z "${servers}" -a -z "${domain}" -a -z "${search}" \
	-a -z "${sortlist}" -a -z "${options}" ] && return 0

	local buffer="# Generated by net-scripts for interface ${IFACE}\n"
	[ -n "${domain}" ] && buffer="${buffer}domain ${domain}\n"
	[ -n "${search}" ] && buffer="${buffer}search ${search}\n"

	for x in ${servers}; do
		buffer="${buffer}nameserver ${x}\n"
	done

	[ -n "${sortlist}" ] && buffer="${buffer}sortlist ${sortlist}\n"
	[ -n "${options}" ] && buffer="${buffer}options ${options}\n"

	# Support resolvconf if we have it.
	if [ -x /sbin/resolvconf ]; then
		printf "${buffer}" | resolvconf -a "${IFACE}"
	else
		printf "${buffer}" > /etc/resolv.conf
		chmod 644 /etc/resolv.conf
	fi
}

_system_ntp() {
	local servers= buffer= x=

	eval servers=\$ntp_servers_${IFVAR}
	[ -z ${servers} ] && servers=${ntp_servers}
	[ -z ${servers} ] && return 0

	buffer="# Generated by net-scripts for interface ${IFACE}\n"
	buffer="${buffer}restrict default noquery notrust nomodify\n"
	buffer="${buffer}restrict 127.0.0.1\n"

	for x in ${servers}; do
		buffer="${buffer}restrict ${x} nomodify notrap noquery\n"
		buffer="${buffer}server ${x}\n"
	done

	printf "${buffer}" > /etc/ntp.conf
	chmod 644 /etc/ntp.conf
}

_system_nis() {
	local servers= domain= x= buffer=

	eval servers=\$nis_servers_${IFVAR}
	[ -z "${servers}" ] && servers=${nis_servers}
	
	eval domain=\$nis_domain_${IFVAR}
	[ -z "${domain}" ] && domain=${nis_domain}
	
	[ -z "${servers}" -a -z "${domain}" ] && return 0

	buffer="# Generated by net-scripts for interface ${iface}\n"

	if [ -n "${domain}" ]; then
		hostname -y "${domain}"
		if [ -n "${servers}" ]; then
			for x in ${servers}; do
				buffer="${buffer}domain ${domain} server ${x}\n"
			done
		else
			buffer="${buffer}domain ${domain} broadcast\n"
		fi
	else
		for x in ${servers}; do
			buffer="${buffer}ypserver ${x}\n"
		done
	fi

	printf "${buffer}" > /etc/yp.conf
	chmod 644 /etc/yp.conf
}

system_pre_start() {
	_system_dns
	_system_ntp 
	_system_nis 

	return 0
}

# vim: set ts=4 :
