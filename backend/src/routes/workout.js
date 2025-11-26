import express from "express";
import prisma from "../prisma.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// Add workout session
router.post("/", auth, async (req, res) => {
  const userId = req.user.id;
  const { reps, validReps, invalidReps, durationSec } = req.body;

  const session = await prisma.workoutSession.create({
    data: { userId, reps, validReps, invalidReps, durationSec },
  });

  res.json(session);
});

// Get user's history
router.get("/", auth, async (req, res) => {
  const userId = req.user.id;
  const sessions = await prisma.workoutSession.findMany({
    where: { userId },
    orderBy: { date: "desc" },
  });

  res.json(sessions);
});

export default router;
