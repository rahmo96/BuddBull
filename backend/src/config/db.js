import mongoose from "mongoose";

export const connectDB = async () => {
    try {
        mongoose.set("debug", true);

        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`Connected to MongoDB: ${conn.connection.name}`);

        mongoose.connection.on("error", (err) => {
            console.error(err);
        });

        mongoose.connection.on("disconnected", () => {
            console.warn("MongoDB disconnected");
        });

        mongoose.connection.on("reconnected", () => {
            console.log("MongoDB reconnected");
        });

    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};
