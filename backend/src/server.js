import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import { User } from "./models/user.js";
import { Sport } from "./models/sports.js";
import { Activity } from "./models/activity.js";
import { ActivityMembership } from "./models/ActivityMembership.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

app.get("/test-create-user", async (req, res) => {
  const user = await User.create({
    email: "test@test.com",
    firstName: "Test",
    lastName: "User",
  });
  res.json(user);
});

app.get("/test-create-sport", async (req, res) => {
  const sport = await Sport.create({
    name: "Test Sport",
    isActive: true,
  });
  res.json(sport);
});

app.get("/test-create-activity", async (req, res) => {
  const activity = await Activity.create({
    title: "Test Activity",
    sportId: "test-sport-id",
    organizerId: "694d10c95ba028a48db2b88e",
  });
  res.json(activity);
});

app.get("/test-create-activity-membership", async (req, res) => {
  const activityMembership = await ActivityMembership.create({
    userId: "test-user-id",
    activityId: "test-activity-id",
  });
  res.json(activityMembership);
});

await connectDB();

app.listen(process.env.PORT || 3000, () => {
  console.log("🚀 Server running");
});
