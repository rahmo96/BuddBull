import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";

import userRoutes from "../src/routers/userRoutes.js";
import sportRoutes from "../src/routers/sportsRoutes.js";
import activityRoutes from "../src/routers/activityRoutes.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/users", userRoutes);
app.use("/api/sports", sportRoutes);
app.use("/api/activities", activityRoutes);

await connectDB();

app.listen(process.env.PORT || 3000, () => {
  console.log("🚀 Server running with multiple routers");
});