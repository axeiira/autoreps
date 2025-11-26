# Quick Start Guide - AutoReps Backend

Get your backend up and running in 5 minutes!

## Prerequisites Checklist

- [ ] Node.js (v18+) installed
- [ ] PostgreSQL (v14+) installed and running
- [ ] Git (optional, for version control)

## Step-by-Step Setup

### Step 1: Install Dependencies

```bash
npm install
```

### Step 2: Configure Environment

Create a `.env` file:

```bash
# Copy the example file
cp .env.example .env
```

Edit `.env` with your settings:

```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/autoreps_db"
JWT_SECRET="your-secret-key-here"
PORT=3000
```

> **Tip**: Generate a secure JWT secret with:
> ```bash
> node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
> ```

### Step 3: Set Up Database

**Create the database:**

```bash
# Login to PostgreSQL
psql -U postgres

# In psql:
CREATE DATABASE autoreps_db;
\q
```

**Run migrations:**

```bash
npm run generate
npm run migrate
```

### Step 4: Start the Server

```bash
npm run dev
```

You should see:
```
API running on port 3000
```

### Step 5: Test the API

Open a new terminal and test:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Setup Complete!

Your backend is now running at `http://localhost:3000`

## Next Steps

### Test Registration

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Test Login

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Save the token from the response!

### View Database (Optional)

```bash
npm run studio
```

Opens Prisma Studio at `http://localhost:5555`

## Common Issues

### Issue: "Cannot connect to database"

**Solution:**
1. Check if PostgreSQL is running:
   ```bash
   # Windows
   pg_ctl status
   ```
2. Verify DATABASE_URL in `.env`
3. Ensure database exists

### Issue: "Port 3000 already in use"

**Solution:**
Change PORT in `.env`:
```env
PORT=3001
```

### Issue: "Prisma Client not generated"

**Solution:**
```bash
npm run generate
```

## Useful Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run start` | Start production server |
| `npm run migrate` | Run database migrations |
| `npm run studio` | Open Prisma Studio |
| `npm run generate` | Generate Prisma Client |

## API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/health` | Health check | No |
| POST | `/auth/register` | Register user | No |
| POST | `/auth/login` | Login user | No |
| GET | `/user/profile` | Get profile | Yes |
| POST | `/user/profile` | Update profile | Yes |
| GET | `/plan` | Get training plan | Yes |
| POST | `/plan` | Update plan | Yes |
| GET | `/workout` | Get workouts | Yes |
| POST | `/workout` | Log workout | Yes |
| GET | `/analytics/summary` | Get stats | Yes |
| GET | `/analytics/weekly` | Weekly data | Yes |

## Using Protected Endpoints

For endpoints that require authentication, include the JWT token:

```bash
curl http://localhost:3000/user/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Need Help?

- Read the full [README.md](README.md)
- Check the [Troubleshooting section](README.md#troubleshooting)
- Open an issue on GitHub

---

**Happy Coding!**
