import os
import boto3
import pandas as pd
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize SageMaker runtime client
runtime = boto3.client('sagemaker-runtime', region_name=os.getenv('AWS_REGION'))

# Load a few samples from the dataset
df = pd.read_csv('data/penguins.csv')
samples = df.head(3)  # Get first 3 samples

# Convert samples to CSV string format
csv_data = samples.to_csv(index=False)

# Get the endpoint name from environment variable
endpoint_name = os.getenv('ENDPOINT_NAME', 'penguins')

try:
    # Send request to the SageMaker endpoint
    response = runtime.invoke_endpoint(
        EndpointName=endpoint_name,
        ContentType='text/csv',
        Body=csv_data
    )
    
    # Parse and print predictions
    predictions = eval(response['Body'].read().decode())
    print("\nPredictions:")
    for i, pred in enumerate(predictions):
        print(f"Sample {i+1}: {pred}")

except Exception as e:
    print(f"Error making request: {str(e)}") 