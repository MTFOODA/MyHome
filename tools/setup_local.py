"""Create local Docker secrets once; never replace existing credentials."""

import base64
from pathlib import Path
import secrets


def main() -> None:
    destination = Path(__file__).resolve().parents[1] / 'infrastructure' / '.env'
    settings = {
        'POSTGRES_PASSWORD': secrets.token_hex(32),
        'APP_DB_PASSWORD': secrets.token_hex(32),
        'JWT_SECRET': secrets.token_hex(48),
        'DOCUMENT_KEY': base64.urlsafe_b64encode(secrets.token_bytes(32)).decode(),
        'CORS_ORIGINS': 'http://localhost:8080',
        'POSTGRES_PORT': '55432',
    }
    try:
        with destination.open('x', encoding='utf-8', newline='\n') as output:
            output.write(''.join(f'{key}={value}\n' for key, value in settings.items()))
    except FileExistsError:
        print('Existing infrastructure/.env retained; no values changed.')
    else:
        print('Created infrastructure/.env. Keep it private and back up DOCUMENT_KEY.')


if __name__ == '__main__':
    main()
