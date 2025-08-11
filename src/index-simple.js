import { QBusinessClient, CreateAnonymousWebExperienceUrlCommand } from '@aws-sdk/client-qbusiness';
import express from 'express';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Configure AWS SDK client
const client = new QBusinessClient({
  region: process.env.AWS_REGION || 'us-east-1'
});

const app = express();

// Test route
app.get('/test', (req, res) => {
  res.json({
    message: 'Server is working',
    environment: {
      SECRET_NAME: process.env.SECRET_NAME,
      AWS_REGION: process.env.AWS_REGION,
      SESSION_DURATION_MINUTES: process.env.SESSION_DURATION_MINUTES
    }
  });
});

// Homepage
app.get('/', async (req, res) => {
  try {
    // For now, let's just return a simple response to see if the server works
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>Test Page</title>
      </head>
      <body>
          <h1>Server is working!</h1>
          <p>Environment variables:</p>
          <pre>${JSON.stringify({
            SECRET_NAME: process.env.SECRET_NAME,
            AWS_REGION: process.env.AWS_REGION,
            SESSION_DURATION_MINUTES: process.env.SESSION_DURATION_MINUTES
          }, null, 2)}</pre>
      </body>
      </html>
    `);
  } catch (error) {
    res.status(500).send(`Error: ${error.message}`);
  }
});

// Start the server
const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

export default app;