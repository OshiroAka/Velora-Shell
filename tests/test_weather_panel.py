import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import importlib.machinery
import importlib.util
import io
import json
from datetime import datetime
from unittest.mock import patch
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[1]


class WeatherPanelTests(unittest.TestCase):
    def test_missing_local_clock_uses_provider_timezone_and_reuses_its_cache(self):
        loader=importlib.machinery.SourceFileLoader("weather_timezone",str(ROOT/"scripts/velora-weather-state"))
        spec=importlib.util.spec_from_loader(loader.name,loader)
        weather=importlib.util.module_from_spec(spec)
        loader.exec_module(weather)
        raw={"current_condition":[{"temp_C":"23","observation_time":"09:36 PM"}],
             "weather":[{"date":"2026-10-15","hourly":[{"time":"1800","tempC":"18"},{"time":"2100","tempC":"20"}]}]}
        encoded=json.dumps(raw).encode()
        responses=[io.BytesIO(encoded),io.BytesIO(b"America/Sao_Paulo\n"),io.BytesIO(encoded)]
        with patch.object(weather.urllib.request,"urlopen",side_effect=responses) as requests, \
             patch.object(weather,"load_cache",return_value={}) as cache, \
             patch.object(weather,"configured_location",return_value="Sao Paulo"), \
             patch.object(weather,"datetime",wraps=datetime) as clock:
            clock.now.return_value=datetime(2026,10,15,19,5,tzinfo=ZoneInfo("America/Sao_Paulo"))
            first=weather.fetch_weather()
            self.assertEqual(first["timezone"],"America/Sao_Paulo")
            self.assertEqual([item["time"] for item in first["hourly"]],["Agora","21:00"])
            self.assertEqual(first["hourly"][0]["temp"],first["temp"])
            self.assertIn("format=%25Z",requests.call_args_list[1].args[0].full_url)
            cache.return_value=first
            second=weather.fetch_weather()
            self.assertEqual(second["timezone"],first["timezone"])
            self.assertEqual(requests.call_count,3,"Cached timezone should avoid another HTTP request")

    def test_hourly_starts_with_observation_and_advances_in_provider_local_time(self):
        loader=importlib.machinery.SourceFileLoader("weather_state",str(ROOT/"scripts/velora-weather-state"))
        spec=importlib.util.spec_from_loader(loader.name,loader)
        weather=importlib.util.module_from_spec(spec)
        loader.exec_module(weather)
        current={"localObsDateTime":"2026-10-15 11:55 PM","temp_C":"0","humidity":"0","windspeedKmph":"0","weatherDesc":[{"value":"Thunderstorm with rain"}]}
        hour=lambda clock,temp: {"time":str(clock),"tempC":str(temp),"chanceofrain":"75"}
        raw={"current_condition":[current],"weather":[
            {"date":"2026-10-15","hourly":[hour(0,99),hour(1800,18),hour(2100,21)]},
            {"date":"2026-10-16","hourly":[hour(300,3),hour(0,1),hour(2500,88)]}]}
        result=weather.normalize_hourly(raw)
        self.assertEqual([item["time"] for item in result],["Agora","00:00","03:00"])
        self.assertEqual(result[0]["temp"],"0")
        self.assertEqual(result[0]["wind"],"0")
        self.assertEqual(result[0]["rain"],"75")
        self.assertEqual(result[0]["icon"],"storm")
        self.assertEqual(result[1]["date"],"2026-10-16")
        self.assertEqual(len(weather.normalize_hourly(raw,1)),1)
        self.assertEqual(weather.normalize_hourly(raw,0),[])
        current["localObsDateTime"]="2026-10-15 18:05"
        self.assertEqual([item["time"] for item in weather.normalize_hourly(raw)],["Agora","21:00","00:00","03:00"])
        current["localObsDateTime"]="unavailable"
        self.assertEqual([item["time"] for item in weather.normalize_hourly(raw)],["Agora"])
        self.assertEqual(weather.normalize_hourly(raw)[0]["rain"],"--")
        self.assertEqual(weather.weather_icon("Parcialmente nublado"),"partly")

    def test_climate_layout_input_graph_retarget_and_lifecycle(self):
        runner = Path('/usr/lib/qt6/bin/qmltestrunner')
        if not runner.is_file():
            self.skipTest('Qt Quick Test required')
        with tempfile.TemporaryDirectory(prefix='velora-weather-test-') as temporary:
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', XDG_RUNTIME_DIR=temporary,
                       QT_QUICK_BACKEND='software')
            env.pop('WAYLAND_DISPLAY', None)
            fixture = (ROOT / 'tests/fixtures/tst_weather_panel.qml').read_text()
            fixture = fixture.replace('"../../', '"' + ROOT.as_uri() + '/')
            artifact = os.environ.get('VELORA_WEATHER_PREVIEW', '')
            if artifact:
                import json
                fixture = fixture.replace('property string artifactPath: ""',
                                          'property string artifactPath: ' + json.dumps(artifact))
            test = Path(temporary) / 'tst_weather_panel.qml'
            test.write_text(fixture)
            result = subprocess.run([str(runner), '-input', str(test)], env=env,
                                    capture_output=True, text=True, timeout=25)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            for error in ('QWARN', 'ReferenceError', 'TypeError', 'Binding loop'):
                self.assertNotIn(error, output)


if __name__ == '__main__':
    unittest.main()
