import { QBusinessClient, CreateAnonymousWebExperienceUrlCommand } from '@aws-sdk/client-qbusiness';
import express from 'express';
import * as dotenv from 'dotenv';
import { getStyles } from './utils.js';
import { getQBusinessConfig } from './secrets.js';

// Load environment variables
dotenv.config();

// Configure AWS SDK client to use the default credential provider chain
// This will automatically use the IAM role associated with the Amplify Compute environment
const client = new QBusinessClient({
  region: process.env.AWS_REGION || 'us-east-1'
});

// Cache for Q Business configuration
let qbusinessConfig = null;

// Session management
class SessionManager {
  constructor() {
    this.sessions = new Map();
  }

  create(durationMinutes) {
    const sessionId = Date.now().toString();
    this.sessions.set(sessionId, {
      createdAt: Date.now(),
      durationMinutes
    });
    return sessionId;
  }

  getStatus(sessionId) {
    const session = this.sessions.get(sessionId);
    if (!session) return { remainingSeconds: 0 };
    
    const elapsed = Math.floor((Date.now() - session.createdAt) / 1000);
    const totalSeconds = session.durationMinutes * 60;
    const remainingSeconds = Math.max(0, totalSeconds - elapsed);
    
    return { remainingSeconds };
  }
}

const sessionManager = new SessionManager();

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
    
    // Track session
    const sessionDuration = parseInt(process.env.SESSION_DURATION_MINUTES || '15', 10);
    const sessionId = sessionManager.create(sessionDuration);
    
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
                          <span id="timer">Session expires in ${sessionDuration}:00</span>
                      </div>
                      <a href="javascript:location.reload()" class="btn">New Session</a>
                  </div>
              </div>
          <script>
            const sessionId = '${sessionId}';
            let remainingSeconds = ${sessionDuration * 60};
            
            async function syncWithServer() {
              try {
                const response = await fetch('/api/session-status/' + sessionId);
                const data = await response.json();
                remainingSeconds = data.remainingSeconds;
              } catch (error) {
                console.error('Failed to sync with server:', error);
              }
            }
            
            function updateTimer() {
              const minutes = Math.floor(remainingSeconds / 60);
              const seconds = remainingSeconds % 60;
              const display = minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
              
              const timerElement = document.getElementById('timer');
              if (timerElement) {
                if (remainingSeconds > 0) {
                  timerElement.textContent = 'Session expires in ' + display;
                  remainingSeconds--;
                } else {
                  timerElement.textContent = 'Session expired';
                  timerElement.style.color = 'red';
                  document.getElementById('qbusiness-iframe').style.display = 'none';
                }
              }
            }
            
            setInterval(updateTimer, 1000);
            setInterval(syncWithServer, 30000); // Sync every 30 seconds
            window.addEventListener('visibilitychange', () => {
              if (!document.hidden) syncWithServer(); // Sync when page becomes visible
            });
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
    console.error('Error:', error);
    res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
          <title>QBusiness Anonymous Chat - Error</title>
          <style>
              body { margin: 0; padding: 20px; font-family: Arial, sans-serif; }
          </style>
      </head>
      <body>
          <div>Error loading QBusiness Anonymous Chat. See logs for more details.</div>
      </body>
      </html>
    `);
  }
});

// Session status endpoint
app.get('/api/session-status/:sessionId', (req, res) => {
  const status = sessionManager.getStatus(req.params.sessionId);
  res.json(status);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Start the server if this file is run directly
// In ES modules, we can check if this is the main module by comparing import.meta.url
const isMainModule = import.meta.url.endsWith(process.argv[1].replace(/^file:\/\//, ''));

if (isMainModule) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
}

// Export the app for Amplify Compute
export default app;