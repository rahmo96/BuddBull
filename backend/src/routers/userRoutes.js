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

router.put("/profile", async (req, res) => {
    try {
        const { firebaseUid, personalInfo } = req.body;

        if (!firebaseUid) {
            return res.status(400).json({ message: "firebaseUid is required" });
        }

        const updatedUser = await User.findOneAndUpdate(
            { firebaseUid },
            { $set: { personalInfo } },
            { new: true, runValidators: true }
        );

        if (!updatedUser) {
            return res.status(404).json({ message: "User not found" });
        }

        res.json(updatedUser);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});



export default router;