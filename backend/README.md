# AutoReps Backend API

Backend API for the AutoReps workout tracking application built with Express.js, Prisma ORM, and PostgreSQL.

##  Features

- **Authentication**: JWT-based authentication with bcrypt password hashing
- **User Management**: User profiles with age, weight, goals, and experience levels
- **Training Plans**: Customizable workout plans with reps, sets, and form tracking
- **Workout Sessions**: Track workout sessions with rep counts and duration
- **Analytics**: Workout analytics and progress tracking
- **Streak Tracking**: Monitor user workout streaks

##  Prerequisites

Before you begin, ensure you have the following installed:
- [Node.js](https://nodejs.org/) (v18 or higher)
- [PostgreSQL](https://www.postgresql.org/) (v14 or higher)
- npm or yarn package manager

##  Installation

### 1. Clone the repository (if not already done)

```bash
cd backend-autoreps
```

### 2. Install dependencies

```bash
npm install
```

### 3. Set up environment variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit the `.env` file with your configuration:

```env
# Database Configuration
DATABASE_URL="postgresql://username:password@localhost:5432/autoreps_db?schema=public"

# JWT Secret (Generate a strong random string for production)
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"

# Server Configuration
PORT=3000
NODE_ENV=development
```

### 4. Set up PostgreSQL Database

**Option A: Using local PostgreSQL**

1. Install PostgreSQL on your system
2. Create a new database:

```bash
# Login to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE autoreps_db;

# Exit psql
\q
```

3. Update your `.env` file with the correct credentials:
```env
DATABASE_URL="postgresql://postgres:your_password@localhost:5432/autoreps_db?schema=public"
```

**Option B: Using Docker**

```bash
docker run --name autoreps-postgres -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DB=autoreps_db -p 5432:5432 -d postgres:14
```

Update `.env`:
```env
DATABASE_URL="postgresql://postgres:mysecretpassword@localhost:5432/autoreps_db?schema=public"
```

### 5. Run Prisma Migrations

Generate Prisma Client and run migrations:

```bash
npm run generate
npm run migrate
```

This will:
- Generate the Prisma Client
- Create all database tables based on the schema
- Apply any pending migrations

### 6. (Optional) Open Prisma Studio

To view and edit your database with a GUI:

```bash
npm run studio
```

This will open Prisma Studio at `http://localhost:5555`

##  Running the Application

### Development Mode (with auto-reload)

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

The server will start on `http://localhost:3000` (or the PORT specified in `.env`)

##  API Endpoints

### Authentication

- `POST /auth/register` - Register a new user
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "securepassword"
  }
  ```

- `POST /auth/login` - Login user
  ```json
  {
    "email": "john@example.com",
    "password": "securepassword"
  }
  ```

### User Management

- `GET /user/profile` - Get user profile (requires auth)
- `POST /user/profile` - Create/update user profile (requires auth)
- `GET /user/me` - Get current user info (requires auth)

### Training Plans

- `GET /plan` - Get user's training plan (requires auth)
- `POST /plan` - Create/update training plan (requires auth)

### Workout Sessions

- `GET /workout` - Get all workout sessions (requires auth)
- `POST /workout` - Log a new workout session (requires auth)

### Analytics

- `GET /analytics/stats` - Get workout statistics (requires auth)
- `GET /analytics/progress` - Get progress over time (requires auth)

### Health Check

- `GET /health` - Check API status

##  Authentication

Protected routes require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

After logging in, you'll receive a token that's valid for 7 days.

## 📊 Database Schema

### Models

- **User**: Core user account information
- **UserProfile**: Extended user profile (age, weight, goals, experience)
- **TrainingPlan**: User's workout plan configuration
- **WorkoutSession**: Individual workout session records
- **UserStreak**: Workout streak tracking

See `prisma/schema.prisma` for the complete schema definition.

##  Testing

Test the API health:

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

##  Available Scripts

- `npm run dev` - Start development server with nodemon
- `npm start` - Start production server
- `npm run migrate` - Run Prisma migrations
- `npm run studio` - Open Prisma Studio
- `npm run generate` - Generate Prisma Client

## 🔧 Troubleshooting

### Database Connection Issues

1. Verify PostgreSQL is running:
   ```bash
   # Windows
   pg_ctl status
   
   # Linux/Mac
   sudo service postgresql status
   ```

2. Check your DATABASE_URL in `.env`
3. Ensure the database exists
4. Verify credentials are correct

### Prisma Issues

If you encounter Prisma errors:

```bash
# Reset the database (WARNING: This will delete all data)
npx prisma migrate reset

# Or regenerate the Prisma Client
npm run generate
```

### Port Already in Use

If port 3000 is already in use, change the PORT in your `.env` file:

```env
PORT=3001
```

##  Deployment

### Environment Variables for Production

Make sure to set these in your production environment:

- `DATABASE_URL` - Your production PostgreSQL connection string
- `JWT_SECRET` - A strong, randomly generated secret
- `PORT` - Server port (optional, defaults to 3000)
- `NODE_ENV=production`
- `CORS_ORIGIN` - Your frontend URL (e.g., `https://yourapp.com`)

### Deployment Platforms

This backend can be deployed to:
- **Heroku** (with Heroku Postgres)
- **Railway** (with Railway Postgres)
- **Render** (with Render Postgres)
- **AWS** (with RDS)
- **DigitalOcean** (with Managed Postgres)

##  Project Structure

```
backend-autoreps/
├── prisma/
│   ├── migrations/       # Database migrations
│   └── schema.prisma     # Database schema
├── src/
│   ├── middleware/
│   │   └── auth.js       # JWT authentication middleware
│   ├── routes/
│   │   ├── auth.js       # Authentication routes
│   │   ├── user.js       # User management routes
│   │   ├── plan.js       # Training plan routes
│   │   ├── workout.js    # Workout session routes
│   │   └── analytics.js  # Analytics routes
│   ├── index.js          # Express app entry point
│   └── prisma.js         # Prisma client instance
├── .env                  # Environment variables (not in git)
├── .env.example          # Environment variables template
├── .gitignore
├── package.json
└── README.md
```


