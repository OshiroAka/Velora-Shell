"""Keep private integration state and backups outside publication candidates."""
import pathlib
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class PublicationHygieneTests(unittest.TestCase):
    def test_tracked_files_do_not_bypass_publication_exclusions(self):
        tracked = subprocess.run(
            ['git', 'ls-files', '-z'], cwd=ROOT,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        if tracked.returncode:
            self.skipTest('requires a Git checkout')
        result = subprocess.run(
            ['git', 'check-ignore', '--no-index', '-z', '--stdin'],
            cwd=ROOT, input=tracked.stdout,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        self.assertIn(result.returncode, (0, 1), result.stderr.decode())
        ignored = set(result.stdout.decode().rstrip('\0').split('\0')) - {''}
        # The development checkout retains its existing root documentation.
        self.assertEqual(ignored - {'README.md'}, set())

    def test_private_files_and_backups_are_ignored_at_any_depth(self):
        private = [
            '.env', '.env.production', '.envrc', 'credentials.json',
            'secrets.json', 'creds.json', 'id_rsa', 'id_ed25519',
            'id_ecdsa', 'id_dsa', 'account.key', 'account.pem',
            'account.p12', 'account.pfx', 'account.ppk', 'account.jks',
            'account.keystore', 'account.keytab', 'passwords.kdbx',
            'chat.db', 'chat.db-wal', 'chat.db-shm', 'chat.db3',
            'chat.sqlite', 'chat.sqlite-wal', 'chat.sqlite-shm',
            'chat.sqlite-journal', 'chat.sqlite3', 'chat.sqlite3-journal',
            'chat.session', 'chat.session-journal', 'chat.session-wal',
            'chat.session-shm', 'source.bak', 'source.old',
            'source.before-change', 'source.orig', 'source.rej',
            'backup/file.json', 'backups/file.json',
            'auth_info_baileys/creds.json', 'auth_info_baileys/session-1.json',
            'baileys_auth_info/session-1.json', '.wwebjs_auth/account.json',
            '.wwebjs_cache/account.json', '.npmrc', '.netrc',
            'source.bundle', 'source.tar', 'source.tar.gz', 'source.tar.zst',
            'source.tar.xz', 'source.tar.bz2', 'source.tgz', 'source.tzst',
            'source.txz', 'source.tbz2', 'source.zip', 'source.7z',
            'source.rar', 'data.sql.gz', 'data.sql.zst',
        ]
        candidates = [prefix + p for prefix in ('', 'integrations/example/') for p in private]
        with tempfile.TemporaryDirectory() as tmp:
            repo = pathlib.Path(tmp)
            subprocess.run(['git', 'init', '-q', tmp], check=True)
            (repo / '.gitignore').write_bytes((ROOT / '.gitignore').read_bytes())
            result = subprocess.run(
                ['git', 'check-ignore', '--no-index', '-z', '--stdin'],
                cwd=repo, input=('\0'.join(candidates) + '\0').encode(),
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
            )
            ignored = set(result.stdout.decode().rstrip('\0').split('\0'))
            self.assertEqual(set(candidates) - ignored, set())
            sources = [
                'config/default.json', 'config/example.json', 'config/schema.json',
                'integrations/whatsapp/store.mjs',
                'integrations/whatsapp/test/session-worker.mjs',
                'integrations/whatsapp/package-lock.json',
                'scripts/install-session', 'scripts/velora-session-agent',
                'tests/fixtures/whatsapp-service.qml',
                'shaders/topbar-connected.frag.qsb',
                'assets/fonts/NotoColorEmoji.ttf',
            ]
            result = subprocess.run(
                ['git', 'check-ignore', '--no-index', '-z', '--stdin'],
                cwd=repo, input=('\0'.join(sources) + '\0').encode(),
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            )
            self.assertEqual(result.returncode, 1, result.stderr.decode())
            self.assertEqual(result.stdout, b'')


if __name__ == '__main__':
    unittest.main()
