import express from "express";
import { Sport } from "../models/sports.js";
const router = express.Router();

router.get("/", async (req, res) => {
    const sports = await Sport.find({ isActive: true });
    res.json(sports);
});

router.post("/", async (req, res) => {
    const newSport = await Sport.create(req.body);
    res.status(201).json(newSport);
});

export default router;