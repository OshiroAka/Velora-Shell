"""Send a Hyprland output to a DLNA renderer using its UPnP AVTransport service."""
import http.client
from http.server import ThreadingHTTPServer
from pathlib import Path
import re
import socket
import sys
import tempfile
import threading
import time
from urllib.parse import urljoin, urlsplit
from xml.etree import ElementTree as XML


SOAP = "http://schemas.xmlsoap.org/soap/envelope/"
AVTRANSPORT = re.compile(r"urn:schemas-upnp-org:service:AVTransport:[0-9]+")
FLUXCAST_DIR = Path("/opt/fluxcast")
UPNP_ERRORS = (OSError, ValueError, RuntimeError, http.client.HTTPException, XML.ParseError)


def request_xml(address, url, method="GET", payload=None, headers=None, timeout=0.8):
    parsed = urlsplit(url)
    if parsed.scheme != "http" or parsed.hostname != address or parsed.username or parsed.password:
        raise ValueError("O endereço UPnP não pertence ao dispositivo encontrado.")
    path = parsed.path or "/"
    if parsed.query:
        path += "?" + parsed.query
    connection = http.client.HTTPConnection(address, parsed.port or 80, timeout=timeout)
    try:
        connection.request(method, path, body=payload, headers=headers or {})
        response = connection.getresponse()
        data = response.read(65_537)
        if len(data) > 65_536 or b"<!DOCTYPE" in data:
            raise ValueError("Resposta UPnP inválida.")
        document = XML.fromstring(data) if data else None
        if not 200 <= response.status < 300:
            detail = document.findtext(".//{*}errorDescription") if document is not None else ""
            raise RuntimeError(detail or f"Resposta UPnP HTTP {response.status}")
        return document
    finally:
        connection.close()


def renderer_description(address, location):
    document = request_xml(address, location)
    if document is None:
        return "", None
    name = document.findtext(".//{*}friendlyName") or ""
    base = document.findtext("./{*}URLBase") or location
    if urlsplit(base).hostname != address:
        base = location
    for device in document.findall(".//{*}device"):
        for service in device.findall("./{*}serviceList/{*}service"):
            service_type = service.findtext("{*}serviceType") or ""
            control = service.findtext("{*}controlURL") or ""
            if AVTRANSPORT.fullmatch(service_type) and control:
                endpoint = urljoin(base, control)
                parsed = urlsplit(endpoint)
                if parsed.scheme == "http" and parsed.hostname == address and not parsed.username and not parsed.password:
                    label = device.findtext("{*}friendlyName") or name
                    return label, (endpoint, service_type)
    return name, None


def avtransport(address, renderer, action, **arguments):
    endpoint, service = renderer
    envelope = XML.Element(f"{{{SOAP}}}Envelope", {f"{{{SOAP}}}encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/"})
    body = XML.SubElement(envelope, f"{{{SOAP}}}Body")
    call = XML.SubElement(body, f"{{{service}}}{action}")
    XML.SubElement(call, "InstanceID").text = "0"
    for key, value in arguments.items():
        XML.SubElement(call, key).text = value
    headers = {"Content-Type": 'text/xml; charset="utf-8"', "SOAPAction": f'"{service}#{action}"'}
    return request_xml(address, endpoint, "POST", XML.tostring(envelope, encoding="utf-8", xml_declaration=True),
                       headers, timeout=4)


def set_playback(address, renderer, uri, mime_type):
    metadata = XML.Element("DIDL-Lite", {"xmlns": "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"})
    item = XML.SubElement(metadata, "item", {"id": "1", "parentID": "0", "restricted": "1"})
    XML.SubElement(item, "{http://purl.org/dc/elements/1.1/}title").text = "Velora Shell"
    XML.SubElement(item, "{urn:schemas-upnp-org:metadata-1-0/upnp/}class").text = "object.item.videoItem"
    features = "DLNA.ORG_PN=AVC_TS_MP_HD_AAC;DLNA.ORG_OP=01" if mime_type == "video/mpeg" else "*"
    XML.SubElement(item, "res", {"protocolInfo": f"http-get:*:{mime_type}:{features}"}).text = uri
    avtransport(address, renderer, "SetAVTransportURI", CurrentURI=uri, CurrentURIMetaData=XML.tostring(metadata, encoding="unicode"))
    avtransport(address, renderer, "Play", Speed="1")


def wait_for_playlist(directory, process):
    path = Path(directory) / "stream.m3u8"
    deadline = time.monotonic() + 25
    while time.monotonic() < deadline and process.poll() is None:
        if path.is_file():
            lines = path.read_text().splitlines()
            segments = [line for line in lines if re.fullmatch(r"stream[0-9]+\.ts", line)]
            if segments and all((path.parent / segment).is_file() for segment in segments):
                return
        time.sleep(0.25)
    raise RuntimeError("A captura do monitor não produziu vídeo.")


def start_playback(address, renderer, stream_base, request_seen, process):
    error = "O receptor não solicitou o vídeo."
    for asset, mime_type in (("stream.m3u8", "application/x-mpegurl"), ("progressive.ts", "video/mpeg")):
        request_seen.clear()
        try:
            set_playback(address, renderer, stream_base + asset, mime_type)
        except UPNP_ERRORS as exc:
            error = str(exc)
            continue
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline and process.poll() is None:
            if request_seen.wait(0.25):
                return
        if process.poll() is not None:
            raise RuntimeError("A captura do monitor foi interrompida.")
    raise RuntimeError(error)


def stream(address, location, output):
    _, renderer = renderer_description(address, location)
    if renderer is None:
        raise RuntimeError("O dispositivo não disponibilizou controle de vídeo DLNA (AVTransport).")

    sys.path.insert(0, str(FLUXCAST_DIR))
    from capture import gather_monitors, start_capture, stop_capture
    from server import HLSRequestHandler, new_session_id, prepare_hls_dir
    import server as fluxcast_server

    monitor = next((value for value in gather_monitors() if value.name == output), None)
    if monitor is None:
        raise RuntimeError("Não foi possível acessar o monitor selecionado.")
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as route:
        route.connect((address, 9))
        host = route.getsockname()[0]

    request_seen = threading.Event()

    class ReceiverHandler(HLSRequestHandler):
        def send_response(self, code, message=None):
            super().send_response(code, message)
            if code not in {200, 206} or self.command != "GET":
                return
            path = urlsplit(self.path).path
            if (self.client_address[0] == self.server.allowed_client and path.startswith(f"/{session}/")
                    and path.endswith(".ts")):
                request_seen.set()

    with tempfile.TemporaryDirectory(prefix="velora-dlna-") as temporary:
        fluxcast_server.HLS_BASE = str(Path(temporary) / "stream")
        session = new_session_id()
        stream_dir = prepare_hls_dir(session)
        recording = None
        playback_requested = False
        with ThreadingHTTPServer((host, 0), ReceiverHandler) as http:
            http.session_id = session
            http.allowed_client = address
            thread = threading.Thread(target=http.serve_forever, daemon=True)
            thread.start()
            try:
                recording = start_capture(monitor, fps=30, bitrate="3M", output_resolution="1280x720", backend="wf-recorder")
                wait_for_playlist(stream_dir, recording.process)
                playback_requested = True
                start_playback(address, renderer, f"http://{host}:{http.server_port}/{session}/", request_seen, recording.process)
                print("[Velora DLNA] O receptor iniciou a leitura do vídeo.", flush=True)
                stopped = 0
                while recording.process.poll() is None:
                    time.sleep(5)
                    try:
                        state = avtransport(address, renderer, "GetTransportInfo")
                        transport = state.findtext(".//{*}CurrentTransportState") if state is not None else ""
                    except UPNP_ERRORS:
                        transport = ""
                    stopped = stopped + 1 if transport in {"STOPPED", "NO_MEDIA_PRESENT"} else 0
                    if stopped >= 2:
                        raise RuntimeError("O receptor encerrou a reprodução.")
                raise RuntimeError("A captura do monitor foi interrompida.")
            finally:
                if playback_requested:
                    try:
                        avtransport(address, renderer, "Stop")
                    except UPNP_ERRORS:
                        pass
                stop_capture(recording)
                http.shutdown()


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    try:
        stream(*sys.argv[1:])
    except KeyboardInterrupt:
        pass
    except (*UPNP_ERRORS, ImportError) as error:
        print(f"[Velora DLNA] ERROR: {error}", file=sys.stderr)
        sys.exit(1)
