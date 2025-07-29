import docker
import requests
import json
import logging
import time
from datetime import datetime, timezone
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

logLocation = os.getenv('LOG_LOCATIION')
webhookUrl = os.getenv('DISCORD_WEBHOOK')
notificationRole = os.getenv('DISCORD_NOTIFICATION_ROLE')

# Configure logging
logging.basicConfig(filename=logLocation, level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

client = docker.from_env()

def send_embed_webhook(embed):
    data = {
        "content": f"<@&{notificationRole}>",
        "embeds": [embed]
    }

    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(webhookUrl, data=json.dumps(data), headers=headers)
        if response.status_code == 204:
            logging.info("Notification sent successfully.")
        else:
            logging.error(f"Failed to send notification: {response.status_code}, {response.text}")
    except requests.exceptions.RequestException as e:
        logging.error(f"Error sending notification: {e}")
        
def create_embed(title, description, color, fields):
    embed = {
        "title": title,
        "description": description,
        "color": color,
        "fields": fields,
        "timestamp": datetime.utcnow().isoformat()
    }

    return embed

def monitor_docker_events():
    while True:
        try:
            for event in client.events(decode=True):
                if event['Type'] == 'container' and event['Action'] in ['start', 'die']:
                    container_id = event['id'][:12]
                    container_name = event['Actor']['Attributes']['name']
                    status = event['Action']
                    color = 65280 if status == 'start' else 16711680

                    fields = [
                        {"name": "Container Name", "value": container_name, "inline": True},
                        {"name": "Container ID", "value": container_id, "inline": True},
                        {"name": "Status", "value": status.capitalize(), "inline": True},
                    ]
                    embed = create_embed(f"Container {status.capitalize()}", f"Container {container_name} ({container_id}) has {status}ed.", color, fields)
                    logging.info(f"Container {status}: {container_name} ({container_id})")
                    send_embed_webhook(embed)
        except docker.errors.APIError as e:
            logging.error(f"Docker API error: {e}")
            time.sleep(5)
        except Exception as e:
            logging.error(f"Unexpected error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    logging.info("Starting Docker event monitor...")
    embed = create_embed("Docker Event Monitor", "Docker event monitor has started.", 65280, [])
    send_embed_webhook(embed)
    monitor_docker_events()