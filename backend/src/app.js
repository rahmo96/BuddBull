import express from "express";
import cors from "cors";

import userRoutes from "./routers/userRoutes.js";
import sportRoutes from "./routers/sportsRoutes.js";
import activityRoutes from "./routers/activityRoutes.js";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/users", userRoutes);
app.use("/api/sports", sportRoutes);
app.use("/api/activities", activityRoutes);

export default app;
