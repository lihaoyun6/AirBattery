/*
 * wificonnection.c
 * Simple utility to get or set the "EnableWifiConnections" option of devices
 *
 * Copyright (c) 2024  lihaoyun6, All Rights Reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#define TOOL_NAME "wificonnection"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#ifndef WIN32
#include <signal.h>
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>

static void print_usage(int argc, char** argv, int is_error)
{
	char *name = strrchr(argv[0], '/');
	fprintf(is_error ? stderr : stdout, "Usage: %s [OPTIONS] [STATUS]\n", (name ? name + 1: argv[0]));
	fprintf(is_error ? stderr : stdout,
		"\n"
		"Display the \"EnableWifiConnections\" status of device or set it to STATUS if specified.\n"
		"\n"
		"OPTIONS:\n"
		"  -u, --udid UDID       target specific device by UDID\n"
		"  -n, --network         connect to network device\n"
		"  -d, --debug           enable communication debugging\n"
		"  -h, --help            print usage information\n"
		"  -v, --version         print version information\n"
	);
}

int main(int argc, char** argv)
{
	int c = 0;
	const struct option longopts[] = {
		{ "udid",    required_argument, NULL, 'u' },
		{ "network", no_argument,       NULL, 'n' },
		{ "debug",   no_argument,       NULL, 'd' },
		{ "help",    no_argument,       NULL, 'h' },
		{ "version", no_argument,       NULL, 'v' },
		{ NULL, 0, NULL, 0}
	};
	int res = -1;
	const char* udid = NULL;
	int use_network = 0;

#ifndef WIN32
	signal(SIGPIPE, SIG_IGN);
#endif

	while ((c = getopt_long(argc, argv, "du:hnv", longopts, NULL)) != -1) {
		switch (c) {
		case 'u':
			if (!*optarg) {
				fprintf(stderr, "ERROR: UDID must not be empty!\n");
				print_usage(argc, argv, 1);
				exit(2);
			}
			udid = optarg;
			break;
		case 'n':
			use_network = 1;
			break;
		case 'h':
			print_usage(argc, argv, 0);
			return 0;
		case 'd':
			idevice_set_debug_level(1);
			break;
		case 'v':
			printf("%s %s\n", TOOL_NAME, PACKAGE_VERSION);
			return 0;
		default:
			print_usage(argc, argv, 1);
			return 2;
		}
	}

	argc -= optind;
	argv += optind;

	if (argc > 1) {
		print_usage(argc, argv, 1);
		return 2;
	}

	idevice_t device = NULL;
	if (idevice_new_with_options(&device, udid, (use_network) ? IDEVICE_LOOKUP_NETWORK : IDEVICE_LOOKUP_USBMUX) != IDEVICE_E_SUCCESS) {
		if (udid) {
			fprintf(stderr, "ERROR: No device found with udid %s.\n", udid);
		} else {
			fprintf(stderr, "ERROR: No device found.\n");
		}
		return -1;
	}

	lockdownd_client_t lockdown = NULL;
	lockdownd_error_t lerr = lockdownd_client_new_with_handshake(device, &lockdown, TOOL_NAME);
	if (lerr != LOCKDOWN_E_SUCCESS) {
		idevice_free(device);
		fprintf(stderr, "ERROR: Could not connect to lockdownd, error code %d\n", lerr);
		return -1;
	}

	if (argc == 0) {
		// getting device name and "EnableWifiConnections" status
		char* name = NULL;
		plist_t value = NULL;
		lockdownd_error_t ret = LOCKDOWN_E_UNKNOWN_ERROR;
		ret = lockdownd_get_value(lockdown, "com.apple.mobile.wireless_lockdown", "EnableWifiConnections", &value);
		lerr = lockdownd_get_device_name(lockdown, &name);
		if (name) {
			printf("%s: ", name);
			free(name);
			res = 0;
		} else {
			res = -1;
			fprintf(stderr, "ERROR: Could not get device name, lockdown error %d\n", lerr);
		}
		if (ret == LOCKDOWN_E_SUCCESS) {
			printf("%s\n", (plist_bool_val_is_true(value)) ? "true" : "false");
			plist_free(value);
			value = NULL;
			res = 0;
		} else {
			res = -1;
			fprintf(stderr, "ERROR: Could not get \"EnableWifiConnections\", lockdown error %d\n", lerr);
		}
	} else {
		// setting device "EnableWifiConnections"
		if (strcmp(argv[0], "true") == 0 || strcmp(argv[0], "false") == 0) {
			uint8_t uint_value = (strcmp(argv[0], "true") == 0) ? 1 : 0;
			lerr = lockdownd_set_value(lockdown, "com.apple.mobile.wireless_lockdown", "EnableWifiConnections", plist_new_bool(uint_value));
			if (lerr == LOCKDOWN_E_SUCCESS) {
				printf("\"EnableWifiConnections\" set to '%s'\n", argv[0]);
				res = 0;
			} else {
				fprintf(stderr, "ERROR: Could not set \"EnableWifiConnections\", lockdown error %d\n", lerr);
			}
		} else {
			fprintf(stderr, "ERROR: status must be \"true\" or \"false\"!\n");
		}
	}

	lockdownd_client_free(lockdown);
	idevice_free(device);

	return res;
}
