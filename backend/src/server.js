import dotenv from "dotenv";
import app from "./app.js";
import { connectDB } from "./config/db.js";

dotenv.config();

await connectDB();

app.listen(process.env.PORT || 3000, () => {
  console.log("🚀 Server running with multiple routers");
});
