import os
import hmac
import hashlib
import subprocess
from flask import Flask, request, abort
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get configuration from environment variables
PORT = int(os.getenv("PORT", 5000))
SECRET = os.getenv("SECRET").encode()
SCRIPT_PATH = os.getenv("SCRIPT_PATH")

app = Flask(__name__)

def verify_signature(payload, signature):
    """Verify the GitHub webhook signature."""
    hash_hex = hmac.new(SECRET, payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(f'sha256={hash_hex}', signature)

@app.route('/deploy', methods=['POST'])
def webhook():
    # Get the signature from the headers
    signature = request.headers.get('X-Hub-Signature-256')
    if not signature:
        abort(400, 'Signature missing')

    # Verify the signature
    if not verify_signature(request.data, signature):
        abort(403, 'Invalid signature')

    try:
        # Open the process and stream output live
        process = subprocess.Popen(
            [SCRIPT_PATH],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1  # Line-buffered
        )

        # Read and print each line as it is produced
        for line in iter(process.stdout.readline, ''):
            print(line, end='')

        process.stdout.close()
        process.wait()

        return 'Script executed successfully', 200

    except subprocess.CalledProcessError as e:
        print(e.stderr)
        return f'Error executing script: {e.stderr}', 500

if __name__ == '__main__':
    # Ensure you run this with unbuffered output (e.g., via `python3 -u app.py`)
    app.run(host='0.0.0.0', port=PORT)
