# 🚀 Deployment Guide - AutoReps

Guide for deploying the AutoReps backend to production.

## 📋 Pre-Deployment Checklist

- [ ] All features tested locally
- [ ] Database schema finalized
- [ ] Environment variables documented
- [ ] Security review completed
- [ ] API documentation up to date
- [ ] Error handling implemented
- [ ] Logging configured

## 🌐 Deployment Options

### Option 1: Railway (Recommended - Easiest)

**Pros:** Free tier, automatic PostgreSQL, easy setup
**Cons:** Limited free tier resources

#### Steps:

1. **Create Railway Account**
   - Go to [railway.app](https://railway.app)
   - Sign up with GitHub

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Connect your repository

3. **Add PostgreSQL**
   - Click "New" → "Database" → "PostgreSQL"
   - Railway automatically creates DATABASE_URL

4. **Configure Environment Variables**
   ```
   DATABASE_URL (auto-generated)
   JWT_SECRET=<generate-strong-secret>
   NODE_ENV=production
   PORT=3000
   CORS_ORIGIN=https://your-app-domain.com
   ```

5. **Deploy**
   - Railway auto-deploys on push to main branch
   - Get your deployment URL

#### Generate JWT Secret:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

### Option 2: Render

**Pros:** Free tier, good documentation
**Cons:** Slower cold starts on free tier

#### Steps:

1. **Create Render Account**
   - Go to [render.com](https://render.com)
   - Sign up with GitHub

2. **Create PostgreSQL Database**
   - New → PostgreSQL
   - Choose free tier
   - Copy internal database URL

3. **Create Web Service**
   - New → Web Service
   - Connect repository
   - Configure:
     ```
     Name: autoreps-api
     Environment: Node
     Build Command: npm install && npm run generate
     Start Command: npm start
     ```

4. **Add Environment Variables**
   ```
   DATABASE_URL=<from-step-2>
   JWT_SECRET=<generate-strong-secret>
   NODE_ENV=production
   CORS_ORIGIN=https://your-app-domain.com
   ```

5. **Deploy**
   - Click "Create Web Service"
   - Wait for deployment

---

### Option 3: Heroku

**Pros:** Mature platform, good documentation
**Cons:** No free tier anymore

#### Steps:

1. **Install Heroku CLI**
   ```bash
   # Windows
   winget install Heroku.HerokuCLI
   
   # Mac
   brew tap heroku/brew && brew install heroku
   ```

2. **Login and Create App**
   ```bash
   heroku login
   cd backend-autoreps
   heroku create autoreps-api
   ```

3. **Add PostgreSQL**
   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

4. **Set Environment Variables**
   ```bash
   heroku config:set JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
   heroku config:set NODE_ENV=production
   heroku config:set CORS_ORIGIN=https://your-app-domain.com
   ```

5. **Deploy**
   ```bash
   git push heroku main
   ```

6. **Run Migrations**
   ```bash
   heroku run npm run migrate
   ```

---

### Option 4: DigitalOcean App Platform

**Pros:** Good performance, managed database
**Cons:** Paid service

#### Steps:

1. **Create DigitalOcean Account**
   - Go to [digitalocean.com](https://www.digitalocean.com)

2. **Create Managed PostgreSQL Database**
   - Create → Databases → PostgreSQL
   - Choose plan and region
   - Copy connection string

3. **Create App**
   - Apps → Create App
   - Connect GitHub repository
   - Select backend-autoreps folder

4. **Configure App**
   ```yaml
   # app.yaml
   name: autoreps-api
   services:
   - name: api
     github:
       repo: your-username/your-repo
       branch: main
       deploy_on_push: true
     build_command: npm install && npm run generate
     run_command: npm start
     envs:
     - key: DATABASE_URL
       value: ${db.DATABASE_URL}
     - key: JWT_SECRET
       type: SECRET
     - key: NODE_ENV
       value: production
   databases:
   - name: db
     engine: PG
   ```

5. **Deploy**
   - Click "Create Resources"

---

### Option 5: AWS (Advanced)

**Pros:** Scalable, full control
**Cons:** Complex setup, requires AWS knowledge

#### Components:
- **EC2:** Application server
- **RDS:** PostgreSQL database
- **Elastic Beanstalk:** Simplified deployment
- **Route 53:** DNS management

#### Quick Setup with Elastic Beanstalk:

1. **Install EB CLI**
   ```bash
   pip install awsebcli
   ```

2. **Initialize**
   ```bash
   cd backend-autoreps
   eb init
   ```

3. **Create Environment**
   ```bash
   eb create autoreps-env
   ```

4. **Set Environment Variables**
   ```bash
   eb setenv DATABASE_URL=<your-rds-url> JWT_SECRET=<secret> NODE_ENV=production
   ```

5. **Deploy**
   ```bash
   eb deploy
   ```

---

## 🔒 Production Security Checklist

### Environment Variables
- [ ] Strong JWT_SECRET (32+ characters, random)
- [ ] Secure DATABASE_URL with strong password
- [ ] CORS_ORIGIN set to specific domain (not *)
- [ ] NODE_ENV=production

### Database
- [ ] Enable SSL connections
- [ ] Regular backups configured
- [ ] Connection pooling enabled
- [ ] Strong database password

### API Security
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints
- [ ] SQL injection protection (Prisma handles this)
- [ ] XSS protection headers
- [ ] HTTPS enforced

### Code
- [ ] Remove console.logs
- [ ] Error messages don't expose sensitive info
- [ ] Dependencies updated
- [ ] No hardcoded secrets

---

## 📊 Monitoring & Logging

### Add Logging (Production)

Install winston:
```bash
npm install winston
```

Create `src/logger.js`:
```javascript
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }));
}

export default logger;
```

Use in routes:
```javascript
import logger from '../logger.js';

router.post('/login', async (req, res) => {
  try {
    // ... login logic
    logger.info(`User logged in: ${email}`);
  } catch (error) {
    logger.error(`Login failed: ${error.message}`);
  }
});
```

### Monitoring Services

- **Sentry:** Error tracking
- **LogRocket:** Session replay
- **New Relic:** Performance monitoring
- **Datadog:** Infrastructure monitoring

---

## 🔄 CI/CD Pipeline

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    
    - name: Install dependencies
      run: |
        cd backend-autoreps
        npm ci
    
    - name: Run tests
      run: |
        cd backend-autoreps
        npm test
    
    - name: Deploy to Railway
      run: |
        npm install -g @railway/cli
        railway up
      env:
        RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

---

## 📱 Flutter App Configuration

### Update API Base URL

After deploying backend, update Flutter app:

**File:** `lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  // Production URL
  static const String baseUrl = 'https://your-api.railway.app';
  
  // Or use environment-based configuration
  static String get baseUrl {
    const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (environment) {
      case 'prod':
        return 'https://your-api.railway.app';
      case 'staging':
        return 'https://staging-api.railway.app';
      default:
        return 'http://localhost:3000';
    }
  }
}
```

Build with environment:
```bash
flutter build apk --dart-define=ENV=prod
```

---

## 🧪 Testing Production

### Health Check
```bash
curl https://your-api-url.com/health
```

### Test Authentication
```bash
# Register
curl -X POST https://your-api-url.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","password":"test123"}'

# Login
curl -X POST https://your-api-url.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'
```

---

## 🔧 Database Migrations in Production

### Railway/Render
Migrations run automatically on deploy if configured.

### Manual Migration
```bash
# SSH into server or use platform CLI
npm run migrate
```

### Heroku
```bash
heroku run npm run migrate
```

---

## 📈 Scaling Considerations

### Database
- Connection pooling (Prisma handles this)
- Read replicas for analytics
- Regular vacuum and analyze

### Application
- Horizontal scaling (multiple instances)
- Load balancer
- Caching layer (Redis)

### CDN
- Static assets on CDN
- API response caching

---

## 🆘 Rollback Plan

### Quick Rollback

**Railway/Render:**
- Go to deployments
- Click on previous working deployment
- Click "Redeploy"

**Heroku:**
```bash
heroku releases
heroku rollback v123
```

**Git-based:**
```bash
git revert HEAD
git push origin main
```

---

## 📊 Post-Deployment Checklist

- [ ] Health endpoint returns 200
- [ ] Authentication works
- [ ] Database migrations applied
- [ ] All endpoints tested
- [ ] CORS configured correctly
- [ ] HTTPS enabled
- [ ] Monitoring setup
- [ ] Backup strategy in place
- [ ] Documentation updated
- [ ] Team notified

---

## 🎯 Performance Optimization

### Database Indexes
```prisma
// Add to schema.prisma
model WorkoutSession {
  // ...
  @@index([userId, date])
}
```

### Compression
```javascript
import compression from 'compression';
app.use(compression());
```

### Rate Limiting
```javascript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

---

## 📞 Support & Maintenance

### Regular Tasks
- [ ] Weekly: Check error logs
- [ ] Monthly: Update dependencies
- [ ] Quarterly: Security audit
- [ ] Yearly: Performance review

### Backup Strategy
- Automated daily database backups
- Keep backups for 30 days
- Test restore procedure monthly

---

**Good luck with your deployment! 🚀**
