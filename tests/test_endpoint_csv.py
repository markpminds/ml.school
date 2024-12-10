import os
import pandas as pd
import requests
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Load a few samples from the dataset
# Get the current file's directory
df = pd.read_csv('data/penguins.csv')
samples = df.sample(10)  # Get samples

# Convert samples to CSV string format
csv_data = samples.to_csv(index=False)

# Get the endpoint URL from environment variable or use default local endpoint
endpoint_url = os.getenv('ENDPOINT_URL', 'http://127.0.0.1:8080/invocations')

# Send request to the model
try:
    response = requests.post(
        endpoint_url,
        headers={'Content-Type': 'text/csv'},
        data=csv_data
    )
    
    if response.status_code == 200:
        predictions = response.json()['predictions']
        print("\nPredictions:")
        for i, pred in enumerate(predictions):
            print(f"Sample {i+1}: {pred}")
    else:
        print(f"Error: Received status code {response.status_code}")
        print(f"Response: {response.text}")

except Exception as e:
    print(f"Error making request: {str(e)}")
