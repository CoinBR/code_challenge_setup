import os
import shutil
import tempfile
import subprocess
import pyotp
import time
import threading
from flask import Flask, request, render_template, send_file, flash, redirect, url_for
from dotenv import load_dotenv
import logging

load_dotenv()

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Configure Flask's logger
logging.basicConfig(level=logging.INFO)
logger = app.logger

TOTP_SECRET = os.environ.get('TOTP_SECRET')
if not TOTP_SECRET:
    raise ValueError("TOTP_SECRET environment variable is not set")

TEMP_DIR = "/tmp/code_challenge_setup"
os.makedirs(TEMP_DIR, exist_ok=True)
logger.info(f"Using temporary directory: {TEMP_DIR}")

def cleanup_temp_files():
    while True:
        try:
            now = time.time()
            for item in os.listdir(TEMP_DIR):
                item_path = os.path.join(TEMP_DIR, item)
                minutes_30 = 1800
                if os.path.isfile(item_path) and now - os.path.getmtime(item_path) > minutes_30:
                    os.remove(item_path)
                    logger.info(f"Cleaned up: {item_path}")
        except Exception as e:
            logger.error(f"Error during cleanup: {e}")
        
        minutes_5 = 300
        time.sleep(minutes_5)

logger.info("Starting cleanup thread")
cleanup_thread = threading.Thread(target=cleanup_temp_files, daemon=True)
cleanup_thread.start()

def validate_totp(code):
    totp = pyotp.TOTP(TOTP_SECRET)
    return totp.verify(code)

@app.route('/')
def root():
    return render_template('landing.html')

@app.route('/<project_name>')
def index(project_name):
    return render_template('index.html', project_name=project_name)

@app.route('/<project_name>/generate', methods=['POST'])
def process_request(project_name):
    totp_code = request.form.get('totp_code')
    github_url = request.form.get('github_url')
    
    if not totp_code or not validate_totp(totp_code):
        flash('Invalid verification code. Please try again.', 'error')
        return redirect(url_for('index', project_name=project_name))
    
    try:
        logger.info("Creating a unique temporary directory")
        temp_dir = tempfile.mkdtemp(dir=TEMP_DIR)
        
        try:
            template_repo = f"git@github.com:CoinBR/{project_name}.git"
            logger.info(f"Cloning repository: {template_repo}")
            subprocess.run(['git', 'clone', template_repo], cwd=temp_dir, check=True)
            
            logger.info("Changing into the repo directory")
            repo_dir = os.path.join(temp_dir, project_name)
            
            logger.info("Initializing and updating git submodules recursively")
            subprocess.run(['git', 'submodule', 'update', '--init', '--recursive', '--remote'],
                           cwd=repo_dir, check=True)
            
            clone_script = os.path.join(repo_dir, 'submodules', 'clone_and_claim', 'run.sh')
            logger.info(f"Running script: {clone_script} with URL: {github_url}")
            os.chmod(clone_script, 0o755)
            subprocess.run([clone_script, github_url], cwd=repo_dir, check=True)
            
            logger.info("Creating tar.gz file with timestamp to ensure uniqueness")
            timestamp = int(time.time())
            archive_path = os.path.join(TEMP_DIR, f"{project_name}_{timestamp}.tar.gz")
            
            shutil.make_archive(
                archive_path[:-7],  # remove '.tar.gz' from the base name
                'gztar',  # use tar.gz format
                root_dir=temp_dir  
            )

            logger.info(f"Temporary directory contents archived to {archive_path}")
            logger.info("Cleaning up the temporary directory")
            shutil.rmtree(temp_dir)

            logger.info("Sending tar.gz file to user for download")
            return send_file(
                archive_path,
                as_attachment=True,
                download_name=f"{project_name}.tar.gz"
            )

        except Exception as e:
            logger.error(f"Error during processing: {str(e)}")
            if os.path.exists(temp_dir):
                shutil.rmtree(temp_dir)
            raise e
            
    except Exception as e:
        logger.error(f"Failed to process request: {str(e)}")
        flash(f'An error occurred: {str(e)}', 'error')
        return redirect(url_for('index', project_name=project_name))

if __name__ == '__main__':
    logger.info(f"Starting Flask application")
    app.run(host='0.0.0.0', port=5000)

