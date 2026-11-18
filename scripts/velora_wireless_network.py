"""Discover devices advertised on the local link through DNS-SD and SSDP."""
from concurrent.futures import ThreadPoolExecutor
import http.client
import ipaddress
import json
import re
import shlex
import socket
import subprocess
import time
from urllib.parse import urlsplit
from xml.etree import ElementTree

from velora_dlna import renderer_description


def interface_addresses():
    try:
        result = subprocess.run(["ip", "-j", "-4", "address", "show", "up"], capture_output=True, text=True, timeout=3)
        return {entry["local"]: entry["prefixlen"] for interface in json.loads(result.stdout)
                if interface.get("link_type") == "ether" and "NOARP" not in interface.get("flags", [])
                for entry in interface.get("addr_info", []) if entry["family"] == "inet"}
    except (OSError, ValueError, KeyError, subprocess.TimeoutExpired):
        return {}


def decode_avahi(value):
    data = re.sub(rb"\\([0-9]{3})", lambda match: bytes((int(match[1]),)) if int(match[1]) < 256 else b"?",
                  value.encode("utf-8"))
    return data.decode("utf-8", "replace")


def device_name(value):
    return " ".join(value.split()).strip()[:120]


def dns_sd():
    try:
        result = subprocess.run(["avahi-browse", "-alrptk"], capture_output=True, text=True, errors="replace", timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return [], False
    entries = []
    for line in result.stdout.splitlines():
        fields = line.split(";", 9)
        if len(fields) != 10 or fields[0] != "=" or fields[5] != "local":
            continue
        instance, service, host, address, port, txt = fields[3], fields[4], fields[6], fields[7], fields[8], fields[9]
        try:
            attributes = dict(record.split("=", 1) for record in shlex.split(txt) if "=" in record)
        except ValueError:
            attributes = {}
        role = "lan"
        label = "Rede local"
        name = host.removesuffix(".local.").removesuffix(".local") or instance
        if service in {"_googlecast._tcp", "_airplay._tcp", "_display._tcp"}:
            role, label = {"_googlecast._tcp": ("cast", "Google Cast"), "_airplay._tcp": ("lan", "AirPlay"),
                           "_display._tcp": ("lan", "Miracast na rede")}[service]
            name = attributes.get("fn") or instance
            capabilities = attributes.get("ca", "")
            if role == "cast" and (port != "8009" or (re.fullmatch(r"[0-9]{1,10}", capabilities)
                                                     and not int(capabilities) & 1)):
                role = "lan"
        entries.append({"address": address, "name": device_name(decode_avahi(name)), "protocol": role, "label": label})
    return entries, result.returncode == 0


def probe_link_neighbors(sources):
    private = tuple(ipaddress.IPv4Network(cidr) for cidr in ("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "169.254.0.0/16"))
    found = set()
    for source, prefix in list(sources.items())[:3]:
        origin = ipaddress.IPv4Address(source)
        subnet = ipaddress.IPv4Network((origin, max(prefix, 24)), strict=False)
        if not any(subnet.subnet_of(block) for block in private):
            continue
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_ICMP) as ping:
                ping.bind((str(origin), 0))
                ping.settimeout(0.2)
                # The kernel supplies the identifier and checksum for a datagram ping socket.
                for index, target in enumerate(subnet.hosts()):
                    if target != origin:
                        ping.sendto(b"\x08\x00\x00\x00\x00\x00\x00\x01VELORA", (str(target), 0))
                    if index % 24 == 23:
                        time.sleep(0.035)
                deadline = time.monotonic() + 1
                while time.monotonic() < deadline:
                    try:
                        reply, (address, _) = ping.recvfrom(1024)
                    except TimeoutError:
                        continue
                    if reply.startswith(b"\x00\x00") and ipaddress.IPv4Address(address) in subnet:
                        found.add(address)
        except OSError:
            continue
    return found


def neighbor_devices(sources):
    addresses = probe_link_neighbors(sources)
    available = bool(addresses)
    try:
        result = subprocess.run(["ip", "-j", "-4", "neigh", "show"], capture_output=True, text=True, timeout=3)
        addresses.update(item["dst"] for item in json.loads(result.stdout) if item.get("lladdr") and item.get("dst"))
        available = available or result.returncode == 0
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    return [{"address": address, "name": address, "protocol": "lan", "label": "Rede local"}
            for address in sorted(addresses)], available


def ssdp_description(address, location):
    try:
        name, renderer = renderer_description(address, location)
        return device_name(name), bool(renderer)
    except (OSError, ValueError, RuntimeError, http.client.HTTPException, ElementTree.ParseError):
        return "", False


def ssdp_replies(source):
    address = ("239.255.255.250", 1900)
    query = b'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 1\r\nST: '
    devices = {}
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 1)
            if source:
                sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_IF, socket.inet_aton(source))
            sock.settimeout(0.35)
            for target in (b"ssdp:all", b"urn:schemas-upnp-org:service:AVTransport:1"):
                sock.sendto(query + target + b"\r\n\r\n", address)
            deadline = time.monotonic() + 2
            while time.monotonic() < deadline and len(devices) < 40:
                try:
                    packet, (host, _) = sock.recvfrom(8192)
                except TimeoutError:
                    continue
                lines = packet.decode("iso-8859-1").splitlines()
                if not lines or not re.match(r"^HTTP/1\.[01] 200\b", lines[0]):
                    continue
                fields = {key.lower(): value.strip() for key, separator, value in (line.partition(":") for line in lines[1:])
                          if separator}
                location = fields.get("location", "")
                advertised = (fields.get("st", "") + " " + fields.get("usn", "")).lower()
                media = ":mediarenderer:" in advertised or ":avtransport:" in advertised
                previous = devices.get(host)
                if previous is None or media and not previous[1]:
                    devices[host] = (location, media)
    except OSError:
        return devices, False
    return devices, True


def ssdp_devices(sources):
    with ThreadPoolExecutor(max_workers=6) as executor:
        scans = list(executor.map(ssdp_replies, sorted(sources)[:6] or [""]))
        replies = {}
        for entries, _ in scans:
            for address, (location, media) in entries.items():
                if address not in replies or media:
                    replies[address] = (location, media)
        selected = list(replies.items())[:40]
        descriptions = executor.map(lambda entry: ssdp_description(entry[0], entry[1][0]), selected)
        devices = []
        for ((address, (location, media)), (name, has_renderer)) in zip(selected, descriptions):
            try:
                url = urlsplit(location)
                is_local = url.scheme == "http" and url.hostname == address and not url.username and not url.password
            except ValueError:
                is_local = False
            can_control = is_local and (has_renderer or media)
            devices.append({"address": address, "name": name or address, "protocol": "dlna" if can_control else "lan",
                            "label": "DLNA" if can_control else "UPnP", "location": location if can_control else ""})
    return devices, any(ok for _, ok in scans)


def discover_network(protocols):
    local = interface_addresses()
    with ThreadPoolExecutor(max_workers=3) as executor:
        dns = executor.submit(dns_sd)
        neighbors = executor.submit(neighbor_devices, local)
        upnp = executor.submit(ssdp_devices, local)
        results = [job.result() for job in (dns, upnp, neighbors)]
    devices = {}
    for entries, _ in results:
        for device in entries:
            try:
                address = ipaddress.ip_address(device["address"])
            except ValueError:
                continue
            if address.is_loopback or address.is_multicast or address.is_unspecified or str(address) in local:
                continue
            protocol = device["protocol"]
            can_connect = protocol in protocols and address.version == 4
            key = str(address)
            candidate = {**device, "name": device["name"] or key, "id": f"lan:{address}", "canConnect": can_connect}
            previous = devices.get(key)
            if not previous or device_priority(candidate) > device_priority(previous):
                devices[key] = candidate
    return list(devices.values()), any(ok for _, ok in results)


def device_priority(device):
    return device["canConnect"], device["label"] != "Rede local", device["name"] != device["address"]
