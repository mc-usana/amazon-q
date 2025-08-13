import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const client = new SecretsManagerClient({
  region: process.env.AWS_REGION || 'us-east-1'
});

export async function getQBusinessConfig() {
  const secretName = process.env.SECRET_NAME || 'qbusiness-config';
  
  console.log('DEBUG: SECRET_NAME from env:', process.env.SECRET_NAME);
  console.log('DEBUG: Using secret name:', secretName);
  console.log('DEBUG: AWS_REGION:', process.env.AWS_REGION);
  
  try {
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await client.send(command);
    return JSON.parse(response.SecretString);
  } catch (error) {
    console.error('Error retrieving secrets:', error);
    throw error;
  }
}