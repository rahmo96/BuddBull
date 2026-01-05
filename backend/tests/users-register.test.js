import request from "supertest";
import app from "../src/app.js";

describe("POST /api/users/register", () => {

  /**
   * Happy Path
   * Verifies that a valid user registration request
   * creates a user and returns HTTP 201
   */
  test("should create user and return 201", async () => {
    const unique = Date.now();

    const payload = {
      firebaseUid: `uid_${unique}`,
      personalInfo: {
        firstName: "Test",
        lastName: "User",
        email: `test_${unique}@example.com`,
        gender: "male",
      },
      location: {
        neighborhood: "Default",
        coordinates: {
          type: "Point",
          coordinates: [34.7818, 32.0853],
        },
      },
      status: "active",
    };

    const res = await request(app)
      .post("/api/users/register")
      .send(payload);

    expect(res.status).toBe(201);
    expect(res.body).toBeTruthy();
    expect(res.body.firebaseUid).toBe(payload.firebaseUid);
    expect(res.body.personalInfo.email).toBe(payload.personalInfo.email);
  });

  /**
   * Duplicate Email
   * Ensures that the system does not allow
   * registering two users with the same email
   */
  test("should fail when email already exists", async () => {
    const unique = Date.now();
    const email = `dup_${unique}@example.com`;

    const payload1 = {
      firebaseUid: `uid_${unique}_1`,
      personalInfo: {
        firstName: "A",
        lastName: "B",
        email,
        gender: "male",
      },
      location: {
        neighborhood: "Default",
        coordinates: {
          type: "Point",
          coordinates: [34.7818, 32.0853],
        },
      },
      status: "active",
    };

    const payload2 = {
      ...payload1,
      firebaseUid: `uid_${unique}_2`, // Different UID, same email
    };

    const res1 = await request(app)
      .post("/api/users/register")
      .send(payload1);

    expect(res1.status).toBe(201);

    const res2 = await request(app)
      .post("/api/users/register")
      .send(payload2);

    expect(res2.status).toBe(400);
    expect(res2.body.message).toBeTruthy();
  });

  /**
   * Missing Required Fields
   * Validates that incomplete payloads
   * are rejected by the API
   */
  test("should fail when required fields are missing", async () => {
    const payload = {
      personalInfo: {
        firstName: "Test",
      },
    };

    const res = await request(app)
      .post("/api/users/register")
      .send(payload);

    expect(res.status).toBe(400);
    expect(res.body.message).toBeTruthy();
  });

});
