# Theme Customization

Customize the government theme to match your organization's branding.

## Theme Assets

Located in `assets/` directory:

- `public-sector-theme.css` - Government color scheme and styling
- `aws-logo.png` - Custom logo (replace with your logo)
- `AmazonEmber_Bd.ttf` - Amazon's official font
- `favicon.ico` - Browser favicon

## Visual Features

### Government Color Scheme
- **Primary Blue**: `#1f4e79` (USWDS compliant)
- **Light Blue**: `#e1f3ff` (user messages)
- **White**: Clean agent responses
- **Professional styling** optimized for accessibility

### Typography
- **Amazon Ember font** (Amazon's official typeface)
- **Clean, readable** text with proper contrast ratios

### Layout
- **Hidden Q Business logo** for clean government branding
- **Mobile responsive** design
- **Session timer** with visual indicators

## Customization Options

### 1. Replace Logo

Replace `assets/aws-logo.png` with your organization's logo:
- Recommended size: 200x50 pixels
- Format: PNG with transparent background
- Upload to S3 after changes

### 2. Update Colors

Edit `assets/public-sector-theme.css`:

```css
/* Primary colors */
:root {
  --primary-blue: #1f4e79;    /* Your primary color */
  --light-blue: #e1f3ff;      /* User message background */
  --text-color: #333;         /* Main text color */
}
```

### 3. Modify Welcome Message

Update in your Q Business web experience:
- Title: "Your Organization AI Assistant"
- Subtitle: "Custom subtitle for your agency"
- Welcome message: "Custom welcome message..."

### 4. Sample Prompts

Customize sample prompts for your organization:
- "What are our current policies?"
- "How do I submit a request?"
- "Where can I find training materials?"

## Applying Changes

### 1. Update Assets

After modifying files in `assets/`:

```bash
# Upload to S3 bucket
aws s3 cp assets/ s3://your-theme-bucket/ --recursive
```

### 2. Update Web Experience

```bash
# Update Q Business configuration
aws qbusiness update-web-experience \
  --application-id YOUR_APP_ID \
  --web-experience-id YOUR_WEB_EXP_ID \
  --title "Your Custom Title" \
  --subtitle "Your Custom Subtitle" \
  --welcome-message "Your custom welcome message"
```

### 3. Redeploy Application

Trigger a new Amplify deployment to pick up changes.

## Advanced Customization

### Custom CSS

Add custom styles to `assets/public-sector-theme.css`:

```css
/* Custom header styling */
.custom-header {
  background: linear-gradient(90deg, #1f4e79, #2d5aa0);
  color: white;
  padding: 1rem;
}

/* Custom button styling */
.custom-button {
  background-color: #1f4e79;
  border: none;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 4px;
}
```

### Environment-Specific Themes

Use different themes for different environments:

```bash
# Development theme
THEME_BUCKET_NAME=dev-theme-bucket

# Production theme  
THEME_BUCKET_NAME=prod-theme-bucket
```

## Accessibility Compliance

The default theme follows accessibility best practices:

- **WCAG 2.1 AA** color contrast ratios
- **Keyboard navigation** support
- **Screen reader** compatibility
- **Mobile responsive** design

When customizing, maintain these standards for compliance.