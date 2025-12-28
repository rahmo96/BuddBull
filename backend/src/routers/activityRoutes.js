import express from "express";
import { Activity } from "../models/activity.js";
const router = express.Router();

router.post("/create", async (req, res) => {
    try {
        const activity = await Activity.create(req.body);
        res.status(201).json(activity);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

export default router;