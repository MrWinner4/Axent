import subprocess
import logging

logger = logging.getLogger(__name__)

def refresh_stockx_token_command():
    try:
        result = subprocess.run(
            ["python", "manage.py", "refresh_stockx_token"],
            check=True,
            capture_output=True,
            text=True
        )
        logger.info("Token refreshed successfully: \n%s", result.stdout)
        return "Success"
    except subprocess.CalledProcessError as e:
        logger.error("Error refreshing token: %s", e.stdout e.stderr)
        return "Error"