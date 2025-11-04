# Backend Deployment Guide for Render

## Environment Variables Configuration

Set these environment variables in your Render backend service dashboard:

### Essential Variables

```bash
# Rails Configuration
RAILS_ENV=production
SECRET_KEY_BASE=cc0e613df9c70c5b81c2651cc9ebbe8f1a624c2171559e96ee1da99d52eb8fef80fc4141c039322c03c969b68e023cc2d380a3541dd49b7df48dfef318732b88

# Database (Render PostgreSQL)
# DATABASE_URL will be automatically provided by Render when you connect your PostgreSQL service

# Server Configuration (Update with your actual Render URLs)
BACKEND_URL=https://your-backend-app.onrender.com
FRONTEND_URL=https://your-frontend-app.onrender.com

# CORS Configuration
ALLOWED_ORIGINS=https://your-frontend-app.onrender.com
```

### Optional Variables (for email functionality)

```bash
# SMTP Configuration (if you want email notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_DOMAIN=gmail.com
```

## Render Service Configuration

### 1. Backend Service Setup

**Service Type:** Web Service
**Environment:** Ruby
**Build Command:**
```bash
bundle install && rails db:migrate && rails db:seed
```

**Start Command:**
```bash
rails server -e production -p $PORT
```

**Branch:** master (or your main branch)

### 2. Database Connection

1. Create a PostgreSQL service on Render
2. Connect it to your backend service
3. Render will automatically set the `DATABASE_URL` environment variable

### 3. Environment Variables in Render Dashboard

Go to your backend service → Environment tab and add:

| Key | Value |
|-----|--------|
| `RAILS_ENV` | `production` |
| `SECRET_KEY_BASE` | `cc0e613df9c70c5b81c2651cc9ebbe8f1a624c2171559e96ee1da99d52eb8fef80fc4141c039322c03c969b68e023cc2d380a3541dd49b7df48dfef318732b88` |
| `BACKEND_URL` | `https://your-backend-app.onrender.com` |
| `FRONTEND_URL` | `https://your-frontend-app.onrender.com` |
| `ALLOWED_ORIGINS` | `https://your-frontend-app.onrender.com` |

### 4. Deployment Steps

1. **Push your code** to GitHub (already done ✅)

2. **Create Render account** and connect to GitHub

3. **Create PostgreSQL Database:**
   - Go to Render Dashboard
   - Click "New" → "PostgreSQL"
   - Choose your database name
   - Select region close to your users
   - Note the database connection details

4. **Create Backend Web Service:**
   - Click "New" → "Web Service"
   - Connect your backend repository
   - Configure as shown above
   - Add all environment variables
   - Connect to PostgreSQL database

5. **Deploy and Test:**
   - Render will automatically build and deploy
   - Check logs for any errors
   - Test GraphQL endpoint: `https://your-backend-app.onrender.com/graphql`

## Frontend Configuration Update

After backend deployment, update your frontend environment:

**Frontend `.env.production`:**
```bash
VITE_GRAPHQL_URL=https://your-backend-app.onrender.com/graphql
VITE_APP_NAME="POS System"
NODE_ENV=production
```

## Important Notes

1. **Free Tier Limitations:** Render free services sleep after inactivity. First request may be slow.

2. **Database Migrations:** Will run automatically during build via `rails db:migrate`

3. **Seed Data:** Will be populated via `rails db:seed`

4. **CORS:** Make sure ALLOWED_ORIGINS matches your frontend URL exactly

5. **Image Uploads:** Active Storage will work with local disk storage on Render

## Troubleshooting

### Common Issues:

1. **Build Fails:** Check Ruby version compatibility in `Gemfile`
2. **Database Connection:** Ensure PostgreSQL service is connected
3. **CORS Errors:** Verify ALLOWED_ORIGINS matches frontend URL
4. **GraphQL Errors:** Check backend logs in Render dashboard

### Testing Deployment:

```bash
# Test GraphQL endpoint
curl https://your-backend-app.onrender.com/graphql

# Test health check (if you add one)
curl https://your-backend-app.onrender.com/health
```

## Next Steps

1. Deploy backend with above configuration
2. Deploy frontend with updated GraphQL URL
3. Test complete workflow
4. Monitor logs for any issues

Your generated secret key is already included above. Just replace the URLs with your actual Render service URLs once created.