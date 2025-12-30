import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
    {
        firebaseUid: { type: String, required: true, unique: true },

        personalInfo: {
            firstName: { type: String, required: true },
            lastName: { type: String, required: true },
            email: { type: String, required: true, unique: true },
            phone: { type: String },
            dateOfBirth: { type: Date },
            gender: { type: String, enum: ["male", "female", "other"] }
        },

        bio: {
            aboutMe: { type: String, maxlength: 500 },
            goals: { type: String }
        },

        profileImage: { type: String },

        sportsInterests: [{ type: String }],
        skillLevels: {
            type: Map,
            of: String
        },

        location: {
            neighborhood: String,
            coordinates: {
                type: { type: String, default: "Point" },
                coordinates: [Number],
            }
        },

        systemRole: {
            type: String,
            enum: ["user", "admin"],
            default: "user"
        },

        streaks: { type: Number, default: 0 },

        status: {
            type: String,
            enum: ["active", "blocked", "deleted"],
            default: "active"
        }
    },
    { timestamps: true }
);

userSchema.index({ "location.coordinates": "2dsphere" });

export const User = mongoose.model("User", userSchema);