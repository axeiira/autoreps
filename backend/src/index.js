import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
dotenv.config();

import authRoutes from "./routes/auth.js";
import userRoutes from "./routes/user.js";
import planRoutes from "./routes/plan.js";
import workoutRoutes from "./routes/workout.js";
import analyticsRoutes from "./routes/analytics.js";

const app = express();

// Middleware
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true
}));
app.use(express.json());

// Routes
app.use("/auth", authRoutes);
app.use("/user", userRoutes);
app.use("/plan", planRoutes);
app.use("/workout", workoutRoutes);
app.use("/analytics", analyticsRoutes);

// Health check endpoint
app.get("/health", (req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
