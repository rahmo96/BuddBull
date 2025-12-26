import mongoose from "mongoose";

const activitySchema = new mongoose.Schema({
    title: String,
    sportId: { type: mongoose.Schema.Types.ObjectId, ref: "Sport" },
    organizerId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    dateTimeStart: Date,
    dateTimeEnd: Date,
    maxPlayers: Number,
    status: { type: String, default: "open" },
});

export const Activity = mongoose.model("Activity", activitySchema);
