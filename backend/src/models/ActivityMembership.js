import mongoose from "mongoose";

const membershipSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    activityId: { type: mongoose.Schema.Types.ObjectId, ref: "Activity" },
    status: { type: String, default: "pending" },
});

membershipSchema.index({ userId: 1, activityId: 1 }, { unique: true });

export const ActivityMembership =
    mongoose.model("ActivityMembership", membershipSchema);
