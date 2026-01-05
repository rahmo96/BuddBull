import express from "express";
import { User } from "../models/user.js";

const router = express.Router();

router.post("/register", async (req, res) => {
    try {
        const { firebaseUid, personalInfo } = req.body;
        // Minimal guard: required fields
        if (!firebaseUid || !personalInfo?.email) {
            return res.status(400).json({ message: "Missing required fields" });
        }
        // Check for existing email (explicit business rule)
        const emailExists = await User.findOne({
            "personalInfo.email": personalInfo.email
        });

        if (emailExists) {
            return res.status(400).json({ message: "Email already exists" });
        }
        // Check for existing firebaseUid
        const uidExists = await User.findOne({ firebaseUid });

        if (uidExists) {
            return res.status(400).json({ message: "firebaseUid already exists" });
        }
        // Original logic – unchanged
        const newUser = await User.create(req.body);
        res.status(201).json(newUser);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

router.put("/profile", async (req, res) => {
    try {
        const { firebaseUid, personalInfo, location } = req.body;
        if (!firebaseUid) return res.status(400).json({ message: "firebaseUid is required" });

        if (location?.coordinates?.coordinates) {
            location.coordinates.coordinates = location.coordinates.coordinates.map(c => parseFloat(c.toFixed(3)));
        }
        
        const update = {
            "personalInfo.firstName": personalInfo?.firstName,
            "personalInfo.lastName": personalInfo?.lastName,
            "personalInfo.email": personalInfo?.email,
            "personalInfo.gender": personalInfo?.gender,
            "personalInfo.dateOfBirth": personalInfo?.birthday ? new Date(personalInfo.birthday) : undefined,
            "sportsInterests": personalInfo?.sportsInterests ?? [],
            "bio.aboutMe": personalInfo?.about ?? "",
            "location": location
        };

        // להוריד שדות שהם undefined כדי שלא ימחקו/יעשו בעיות
        Object.keys(update).forEach((k) => update[k] === undefined && delete update[k]);

        const updatedUser = await User.findOneAndUpdate(
            { firebaseUid },
            { $set: update },
            { new: true, runValidators: true }
        );

        if (!updatedUser) return res.status(404).json({ message: "User not found" });
        res.json(updatedUser);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});





export default router;