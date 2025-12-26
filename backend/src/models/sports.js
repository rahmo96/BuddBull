import mongoose from "mongoose";

const sportSchema = new mongoose.Schema({
    name: { type: String, unique: true },
    isActive: { type: Boolean, default: true },
});
export const Sport = mongoose.model("Sport", sportSchema);
