import express from "express";
import prisma from "../prisma.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// Get profile (protected)
router.get("/profile", auth, async (req, res) => {
  const userId = req.user.id; // datang dari middleware

  const profile = await prisma.userProfile.findUnique({
    where: { userId },
  });

  res.json(profile);
});

// Update or create profile
router.post("/profile", auth, async (req, res) => {
  const userId = req.user.id;
  const { age, weight, primaryGoal, experienceLevel } = req.body;

  const profile = await prisma.userProfile.upsert({
    where: { userId },
    update: { age, weight, primaryGoal, experienceLevel },
    create: { userId, age, weight, primaryGoal, experienceLevel },
  });

  res.json(profile);
});

export default router;
