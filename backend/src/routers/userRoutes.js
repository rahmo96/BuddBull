import express from "express";
import { User } from "../models/user.js";

const router = express.Router();

router.post("/register", async (req, res) => {
    try {
        const newUser = await User.create(req.body);
        res.status(201).json(newUser);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

router.get("/test", async (req, res) => {
    res.json({ message: "User route is working!" });
});

export default router;