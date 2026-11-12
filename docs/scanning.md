# Scan coverage

## Local checks

A scan requires an explicit private IPv4 address and a network-authorisation acknowledgement. It does not guess a subnet, scan public addresses in LAN mode, try passwords, run exploit payloads, change settings or view camera footage.

- TCP connection attempts: **21, 22, 23, 80, 443, 445, 554, 3389, 8000, 8080, 8443, 8554**. Maximum three simultaneous connections and two seconds per connection.
- Passive greetings on reachable 21/22/23: at most 512 bytes retained, no commands sent. SSH identification, Telnet negotiation and explicit FTP greetings are evidence; silence remains unknown.
- ONVIF `GetDeviceInformation` at `/onvif/device_service` on reachable HTTP ports 80/8080. Collects manufacturer, model and firmware only; serial numbers are discarded. Responses are capped at 64 KiB. Information is self-reported, not authenticated device identity.
- RTSP 1.0 `OPTIONS` then `DESCRIBE` at `/` on reachable 554/8554. Only response headers are examined. A 200 response advertising SDP is reported as such; it does not prove video can be viewed. No `SETUP`, `PLAY`, snapshot download or media capture.
- Targeted **unicast** SSDP search to the selected device on UDP 1900. A missing response is inconclusive because implementations and policy differ.
- UPnP description/control URLs must remain on the explicitly selected numeric host. Redirects are not followed. The gateway action is read-only `GetGenericPortMappingEntry`, limited to eight entries. HTTP bodies are capped at 128 KiB and requests time out. A normal end-of-list is distinguished from an unreadable or capped list.

Port numbers suggest services but do not identify them. A service version does not necessarily identify the whole firmware or prove an unpatched component: vendors can backport fixes.

## Native discovery

Bonjour/NSD browses exactly these declared types: `_http._tcp`, `_https._tcp`, `_rtsp._tcp`, `_ssh._tcp`, `_smb._tcp`, `_googlecast._tcp`, `_airplay._tcp`, `_hap._tcp`. Results are self-advertised names and addresses. Only private IPv4 addresses enter this workflow. Discovery is user initiated and bounded; no unrestricted Bonjour service query or raw multicast entitlement is used.

This does not discover all cameras: many use WS-Discovery, proprietary protocols or no advertisement. Sleeping devices, isolation, multicast filtering and separate VLANs can hide assets. An empty inventory is not evidence of an empty network.

## External check without a server

The installed Android/iOS app checks an explicitly authorised, dedicated public IPv4 from cellular connectivity. It rejects private/special-use/CGNAT address ranges and refuses to run on desktop or when connectivity is ambiguous. The user must verify ownership, that the address is not shared, and that Wi-Fi/VPN are off.

Ports: **22, 23, 80, 443, 554, 8554, 8080, 8443**, at most two concurrent connections. RTSP checks run where relevant. Connectivity is checked between batches and before returning results. The sockets are **not interface-bound**: connectivity reporting is a safeguard, not a proof of the packet route. Repeat after any network change. A cellular test from the owner’s phone is not an independent third-party certification.

A successful connection demonstrates reachability in that test, not the identity of the endpoint. Failure can reflect filtering, timeouts or address changes. IPv6, UDP, other ports, cloud/P2P relays and authenticated remote access remain outside this test. CGNAT cannot be ruled out merely because an address looks public. Shared carrier addresses must not be probed.

## Web light

The browser makes a user-initiated HEAD request to an explicit private IP. CORS, HTTPS, mixed-content rules and local network permissions can prevent access or reading the response. `no-cors` is not a workaround: opaque responses cannot supply firmware or vulnerability evidence. A PWA has the same network restrictions.

A custom `netscan://inspect?host=192.168.1.1` link only fills a private IPv4 target in the installed app. It never authorises or starts scanning. Android, iOS and macOS register the scheme; the Windows installer registers it for the current user. Linux scheme registration depends on desktop packaging.

## Inventory and imports

Netscan keeps at most 256 device records with the latest two reports per device. Trust-group labels describe user intent; they do not configure VLANs or firewall rules. IP-based comparison can refer to a different device after DHCP reassignment.

Imports accept Netscan JSON and Nmap XML up to 2 MiB, with bounded report and port counts. Nmap imports include explicitly listed TCP observations and service/version/CPE evidence, not script outputs or UDP. No Nmap executable, scripts, signatures or third-party scanner code are bundled.

Imported observations remain marked as imported and are not independently verified. Change comparison considers only ports explicitly tested in both reports under the same target/profile. Missing tests are not interpreted as closed ports.

## Authoritative references

- [UPnP device architecture](https://openconnectivity.org/developer/specifications/upnp-resources/upnp/)
- [UPnP WANIPConnection specification](https://upnp.org/specs/gw/UPnP-gw-WANIPConnection-v2-Service.pdf)
- [ONVIF cybersecurity recommendations](https://www.onvif.org/profiles/whitepapers/onvif-recommendations-for-cybersecurity-best-practices-for-ip-based-physical-security-products/)
- [RTSP 1.0](https://www.rfc-editor.org/rfc/rfc2326)
- [Apple local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)
- [Chrome local network access](https://developer.chrome.com/docs/modern-web-guidance/guides/security/local-network-access)
