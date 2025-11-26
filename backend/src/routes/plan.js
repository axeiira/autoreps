import express from "express";
import prisma from "../prisma.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// Get plan
router.get("/", auth, async (req, res) => {
  const userId = req.user.id;

  const plan = await prisma.trainingPlan.findUnique({
    where: { userId },
  });

  res.json(plan);
});

// Update or create plan
router.post("/", auth, async (req, res) => {
  const userId = req.user.id;
  const { planName, reps, sets, formStatus } = req.body;

  const plan = await prisma.trainingPlan.upsert({
    where: { userId },
    update: { planName, reps, sets, formStatus },
    create: { userId, planName, reps, sets, formStatus },
  });

  res.json(plan);
});

export default router;
