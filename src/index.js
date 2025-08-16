import { QBusinessClient, CreateAnonymousWebExperienceUrlCommand } from '@aws-sdk/client-qbusiness';
import express from 'express';
import * as dotenv from 'dotenv';
import { getStyles } from './utils.js';
import { getQBusinessConfig } from './secrets.js';

// Load environment variables from .env file only in local development
// Check if we're running locally (not in Amplify/Lambda environment)
import { existsSync } from 'fs';
if (!process.env.AWS_LAMBDA_FUNCTION_NAME && existsSync('config/.env')) {
  dotenv.config({ path: 'config/.env' });
} else {
  dotenv.config();
}

// Log environment variables for debugging
console.log('Environment variables:', {
  QBUSINESS_CONFIG_ID: process.env.QBUSINESS_CONFIG_ID ? 'SET' : 'MISSING',
  REGION: (process.env.AWS_REGION || process.env.REGION) ? 'SET' : 'MISSING',
  SESSION_DURATION_MINUTES: process.env.SESSION_DURATION_MINUTES ? 'SET' : 'MISSING',
  PORT: process.env.PORT || '3000'
});

// Configure AWS SDK client to use the default credential provider chain
// This will automatically use the IAM role associated with the Amplify Compute environment
const client = new QBusinessClient({
  region: process.env.AWS_REGION || process.env.REGION || 'us-east-1'
});

// Cache for Q Business configuration
let qbusinessConfig = null;

// Middleware
const noCacheMiddleware = (req, res, next) => {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
  });
  next();
};

const app = express();
app.use(express.json());

// Homepage with server-side rendering
app.get('/', noCacheMiddleware, async (req, res) => {
  try {
    // Get Q Business configuration from Secrets Manager
    if (!qbusinessConfig) {
      qbusinessConfig = await getQBusinessConfig();
    }
    
    const command = new CreateAnonymousWebExperienceUrlCommand({
      applicationId: qbusinessConfig.QBUSINESS_APP_ID,
      webExperienceId: qbusinessConfig.QBUSINESS_WEB_EXP_ID,
      sessionDurationInMinutes: parseInt(process.env.SESSION_DURATION_MINUTES || '15', 10)
    });
    const response = await client.send(command);
    const anonymousUrl = response.anonymousUrl;
    
    // Session duration
    const sessionDuration = parseInt(process.env.SESSION_DURATION_MINUTES || '15', 10);
    const sessionId = Date.now().toString();
    
    // Send HTML with the iframe already configured
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>AI Assistant</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
              ${getStyles()}
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header">
                  <h1>Demo Government Agency GenAI Chatbot</h1>
              </div>
              <div class="info">
                  <div class="status">
                      <div class="status-left">
                          <div class="status-dot"></div>
                          <span id="timer">Session expires in <span id="session-duration">${sessionDuration}</span>:00</span>
                      </div>
                      <a href="javascript:location.reload()" class="btn">New Session</a>
                  </div>
              </div>
          <script>
            const sessionId = ${JSON.stringify(sessionId)};
            let remainingSeconds = ${parseInt(sessionDuration, 10) * 60};
            

            
            function updateTimer() {
              const minutes = Math.floor(remainingSeconds / 60);
              const seconds = remainingSeconds % 60;
              const display = minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
              
              const timerElement = document.getElementById('timer');
              const durationElement = document.getElementById('session-duration');
              if (timerElement && durationElement) {
                if (remainingSeconds > 0) {
                  durationElement.textContent = display;
                  remainingSeconds--;
                } else {
                  timerElement.textContent = 'Session expired';
                  timerElement.style.color = 'red';
                  document.getElementById('qbusiness-iframe').style.display = 'none';
                }
              }
            }
            
            setInterval(updateTimer, 1000);
            window.onload = updateTimer;
          </script> 
              <div class="iframe-container">
                  <iframe id="qbusiness-iframe" src="${anonymousUrl}"></iframe>
              </div>
              <div class="footer">
                  Coversation history is not available after session expiration.<br>
                  Powered by Amazon Q Business | For technical support, contact your IT administrator
              </div>
          </div>
      </body>
      </html>
    `);
  } catch (error) {
    console.error('Error:', error.message);
    
    res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>AI Assistant - Error</title>
          <style>
              body { margin: 0; padding: 20px; font-family: Arial, sans-serif; }
              .error { background: #f8f8f8; padding: 20px; border: 1px solid #ddd; text-align: center; }
          </style>
      </head>
      <body>
          <div class="error">
              <h2>Service Temporarily Unavailable</h2>
              <p>Please try again in a few moments or contact your IT administrator.</p>
              <a href="/">Retry</a>
          </div>
      </body>
      </html>
    `);
  }
});



// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Global error handler
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error.message);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
});

// Start the server if this file is run directly
// In ES modules, we can check if this is the main module by comparing import.meta.url
const isMainModule = import.meta.url.endsWith(process.argv[1].replace(/^file:\/\//, ''));

if (isMainModule) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

// Export the app for Amplify Compute
export default app;