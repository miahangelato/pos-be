# Email Configuration for Production

## 📧 **Required Environment Variables for Render**

Add these to your Render backend service Environment tab:

```
SMTP_USERNAME=to.miahangela@gmail.com
SMTP_PASSWORD=your-gmail-app-password-here
```

## 🔐 **How to Generate Gmail App Password**

Since your application uses `to.miahangela@gmail.com`, you need to create an **App Password** for Gmail:

### **Step 1: Enable 2-Factor Authentication**
1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Click **Security** in the left panel
3. Under "Signing in to Google", click **2-Step Verification**
4. Follow the setup process if not already enabled

### **Step 2: Generate App Password**
1. Go back to **Security** settings
2. Under "Signing in to Google", click **App passwords**
3. Select app: **Mail**
4. Select device: **Other (custom name)**
5. Enter name: `POS System Render`
6. Click **Generate**
7. **Copy the 16-character password** (it will look like: `abcd efgh ijkl mnop`)

### **Step 3: Add to Render**
1. Go to your Render backend service
2. Navigate to **Environment** tab
3. Add new environment variable:
   - **Key**: `SMTP_PASSWORD`
   - **Value**: The 16-character app password (without spaces)

## ⚙️ **Current Email Configuration**

The application is configured to:
- **Send from**: `to.miahangela@gmail.com`
- **SMTP Server**: `smtp.gmail.com:587`
- **Authentication**: Plain with STARTTLS
- **Send emails for**: Order confirmations, payment notifications

## 🔍 **Alternative: Use a Different Email Service**

If you prefer not to use Gmail, you can:

1. **Use Sendgrid** (Free tier available):
   ```
   SMTP_USERNAME=apikey
   SMTP_PASSWORD=your-sendgrid-api-key
   ```
   
2. **Use Mailgun** (Free tier available):
   ```
   SMTP_USERNAME=your-mailgun-smtp-username
   SMTP_PASSWORD=your-mailgun-smtp-password
   ```

3. **Update the mailer configuration** in `app/mailers/order_mailer.rb` to use your preferred email address.

## 🧪 **Testing Email Delivery**

After adding the credentials, you can test by:
1. Creating a new order in production
2. Check Render logs for email delivery status
3. Verify email arrives at customer's inbox

## 🚨 **Security Note**

- **Never commit** email passwords to Git
- Use **App Passwords** instead of your main Gmail password
- **Revoke unused** app passwords periodically