import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
    {
        email: { type: String, required: true, unique: true },

        firstName: { type: String, required: true },
        lastName: { type: String, required: true },

        roles: {
            isPlayer: { type: Boolean, default: true },
            isOrganizer: { type: Boolean, default: false },
            isAdmin: { type: Boolean, default: false },
        },

        location: {
            area: String,
            radiusKm: { type: Number, default: 5 },
        },

        status: {
            type: String,
            enum: ["active", "blocked", "deleted"],
            default: "active",
        },
    },
    { timestamps: true }
);

export const User = mongoose.model("User", userSchema);
