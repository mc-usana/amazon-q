import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const client = new SecretsManagerClient({
  region: process.env.REGION || process.env.AWS_REGION || 'us-east-1'
});

export async function getQBusinessConfig() {
  const secretName = process.env.QBUSINESS_CONFIG_ID || 'qbusiness-config';
  
  try {
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await client.send(command);
    return JSON.parse(response.SecretString);
  } catch (error) {
    console.error('Error retrieving secrets:', error);
    throw error;
  }
}