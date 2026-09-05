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
#include <strings.h>
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#ifndef WIN32
#include <signal.h>
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>
#include <usbmuxd.h>
#include <plist/plist.h>

/*
 * Sync the "WiFiMACAddress" stored in the host side pair record with the MAC
 * address the device actually uses for its Bonjour announcements.
 *
 * Devices with iOS "Private Wi-Fi Address" enabled (Fixed or Rotating) announce
 * _apple-mobdev2._tcp with a randomized MAC, while the pair record created by
 * Finder/Xcode stores the hardware MAC. macOS usbmuxd matches Bonjour
 * announcements against the pair record's WiFiMACAddress, so on mismatch every
 * announcement is dropped ("Ignoring ... (Pariable=false)") and the device is
 * never attached as a network device. Rewriting the record fixes this without
 * requiring the user to disable Private Wi-Fi Address.
 */
static int sync_pair_record_mac(lockdownd_client_t lockdown, const char* udid)
{
	plist_t val = NULL;
	lockdownd_error_t lerr = lockdownd_get_value(lockdown, "com.apple.mobile.wireless_lockdown", "BonjourFullServiceName", &val);
	if (lerr != LOCKDOWN_E_SUCCESS || !val || plist_get_node_type(val) != PLIST_STRING) {
		fprintf(stderr, "ERROR: Could not get \"BonjourFullServiceName\", lockdown error %d\n", lerr);
		if (val) plist_free(val);
		return -1;
	}

	char *svcname = NULL;
	plist_get_string_val(val, &svcname);
	plist_free(val);
	if (!svcname) return -1;

	/* full service name looks like "<MAC>@<IPv6>-supportsRP-<port>._apple-mobdev2._tcp.local." */
	char *at = strchr(svcname, '@');
	if (!at || at == svcname) {
		fprintf(stderr, "ERROR: Unexpected BonjourFullServiceName: %s\n", svcname);
		free(svcname);
		return -1;
	}
	size_t maclen = (size_t)(at - svcname);
	if (maclen >= 32) maclen = 31;
	char bonjour_mac[32];
	memcpy(bonjour_mac, svcname, maclen);
	bonjour_mac[maclen] = '\0';
	free(svcname);

	char *record_data = NULL;
	uint32_t record_size = 0;
	if (usbmuxd_read_pair_record(udid, &record_data, &record_size) != 0 || !record_data) {
		fprintf(stderr, "ERROR: Could not read pair record for %s (device not paired?)\n", udid);
		return -1;
	}

	plist_t record = NULL;
	if (record_size > 8 && memcmp(record_data, "bplist00", 8) == 0)
		plist_from_bin(record_data, record_size, &record);
	else
		plist_from_xml(record_data, record_size, &record);
	free(record_data);
	if (!record || plist_get_node_type(record) != PLIST_DICT) {
		fprintf(stderr, "ERROR: Failed to parse pair record for %s\n", udid);
		if (record) plist_free(record);
		return -1;
	}

	plist_t mac_node = plist_dict_get_item(record, "WiFiMACAddress");
	char *current_mac = NULL;
	if (mac_node && plist_get_node_type(mac_node) == PLIST_STRING)
		plist_get_string_val(mac_node, &current_mac);

	if (current_mac && strcasecmp(current_mac, bonjour_mac) == 0) {
		printf("Pair record WiFiMACAddress (%s) already matches the Bonjour MAC\n", current_mac);
		free(current_mac);
		plist_free(record);
		return 0;
	}

	if (mac_node) {
		plist_set_string_val(mac_node, bonjour_mac);
	} else {
		plist_dict_set_item(record, "WiFiMACAddress", plist_new_string(bonjour_mac));
	}

	char *new_data = NULL;
	uint32_t new_size = 0;
	plist_to_xml(record, &new_data, &new_size);
	plist_free(record);
	if (!new_data) {
		fprintf(stderr, "ERROR: Failed to serialize updated pair record for %s\n", udid);
		free(current_mac);
		return -1;
	}

	if (usbmuxd_save_pair_record_with_device_id(udid, 0, new_data, new_size) != 0) {
		fprintf(stderr, "ERROR: Could not save updated pair record for %s\n", udid);
		free(new_data);
		free(current_mac);
		return -1;
	}
	printf("Updated WiFiMACAddress in pair record: %s -> %s\n", current_mac ? current_mac : "(none)", bonjour_mac);
	free(new_data);
	free(current_mac);
	return 0;
}

static void print_usage(int argc, char** argv, int is_error)
{
	char *name = strrchr(argv[0], '/');
	fprintf(is_error ? stderr : stdout, "Usage: %s [OPTIONS] [STATUS]\n", (name ? name + 1: argv[0]));
	fprintf(is_error ? stderr : stdout,
		"\n"
		"Display the \"EnableWifiConnections\" status of device or set it to STATUS if specified.\n"
		"The special status \"syncmac\" updates the WiFiMACAddress stored in the host side\n"
		"pair record to match the MAC address used by the device's Bonjour announcements\n"
		"(needed for iOS \"Private Wi-Fi Address\" devices to show up as network devices).\n"
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
		// setting device "EnableWifiConnections" or syncing the pair record MAC
		if (strcmp(argv[0], "syncmac") == 0) {
			if (!udid) {
				fprintf(stderr, "ERROR: syncmac requires --udid!\n");
				res = -1;
			} else {
				res = sync_pair_record_mac(lockdown, udid);
			}
		} else if (strcmp(argv[0], "true") == 0 || strcmp(argv[0], "false") == 0) {
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
