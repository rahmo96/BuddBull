import request from "supertest";
import app from "../src/app.js";

describe("PUT /api/users/profile", () => {

  test("should update user profile successfully (happy path)", async () => {
    const unique = Date.now();

    const registerPayload = {
      firebaseUid: `uid_${unique}`,
      personalInfo: {
        firstName: "Initial",
        lastName: "User",
        email: `test_${unique}@example.com`,
        gender: "male",
      },
      location: {
        neighborhood: "Initial",
        coordinates: {
          type: "Point",
          coordinates: [34.7818123, 32.0853123],
        },
      },
      status: "active",
    };

    await request(app)
      .post("/api/users/register")
      .send(registerPayload)
      .expect(201);

    const updatePayload = {
      firebaseUid: `uid_${unique}`,
      personalInfo: {
        firstName: "Updated",
        lastName: "Name",
        email: `updated_${unique}@example.com`,
        gender: "male",
      },
      location: {
        neighborhood: "Updated",
        coordinates: {
          type: "Point",
          coordinates: [34.1234567, 32.7654321],
        },
      },
    };

    const res = await request(app)
      .put("/api/users/profile")
      .send(updatePayload);

    expect(res.status).toBe(200);
    expect(res.body.personalInfo.firstName).toBe("Updated");
    expect(res.body.personalInfo.lastName).toBe("Name");
    expect(res.body.location.neighborhood).toBe("Updated");
  });

  test("should return 404 when user does not exist", async () => {
    const res = await request(app)
      .put("/api/users/profile")
      .send({
        firebaseUid: "non_existing_uid",
        personalInfo: {
          firstName: "Ghost",
        },
      });

    expect(res.status).toBe(404);
  });

  test("should fail when firebaseUid is missing", async () => {
    const res = await request(app)
      .put("/api/users/profile")
      .send({
        personalInfo: {
          firstName: "NoUID",
        },
      });

    expect(res.status).toBe(400);
    expect(res.body.message).toBeTruthy();
  });

  test("should update partial profile without removing existing data", async () => {
    const unique = Date.now();

    const registerPayload = {
      firebaseUid: `uid_partial_${unique}`,
      personalInfo: {
        firstName: "Original",
        lastName: "User",
        email: `partial_${unique}@example.com`,
        gender: "male",
      },
      location: {
        neighborhood: "Original",
        coordinates: {
          type: "Point",
          coordinates: [34.7818, 32.0853],
        },
      },
      status: "active",
    };

    await request(app)
      .post("/api/users/register")
      .send(registerPayload)
      .expect(201);

    const res = await request(app)
      .put("/api/users/profile")
      .send({
        firebaseUid: `uid_partial_${unique}`,
        personalInfo: {
          firstName: "OnlyUpdated",
        },
      });

    expect(res.status).toBe(200);
    expect(res.body.personalInfo.firstName).toBe("OnlyUpdated");
    expect(res.body.personalInfo.lastName).toBe("User"); // should remain unchanged
    expect(res.body.location.neighborhood).toBe("Original"); // should remain unchanged
  });

  test("should round location coordinates to 3 decimal places", async () => {
    const unique = Date.now();

    const registerPayload = {
      firebaseUid: `uid_round_${unique}`,
      personalInfo: {
        firstName: "Geo",
        lastName: "User",
        email: `geo_${unique}@example.com`,
        gender: "male",
      },
      location: {
        neighborhood: "Geo",
        coordinates: {
          type: "Point",
          coordinates: [34.9999999, 32.1111111],
        },
      },
      status: "active",
    };

    await request(app)
      .post("/api/users/register")
      .send(registerPayload)
      .expect(201);

    const res = await request(app)
      .put("/api/users/profile")
      .send({
        firebaseUid: `uid_round_${unique}`,
        location: {
          neighborhood: "Rounded",
          coordinates: {
            type: "Point",
            coordinates: [34.1234567, 32.7654321],
          },
        },
      });

    expect(res.status).toBe(200);

    const [lng, lat] = res.body.location.coordinates.coordinates;

    expect(lng).toBeCloseTo(34.123, 3);
    expect(lat).toBeCloseTo(32.765, 3);
  });

  test("should update email successfully", async () => {
    const unique = Date.now();

    const registerPayload = {
      firebaseUid: `uid_email_${unique}`,
      personalInfo: {
        firstName: "Email",
        lastName: "User",
        email: `email_${unique}@example.com`,
        gender: "male",
      },
      location: {
        neighborhood: "Email",
        coordinates: {
          type: "Point",
          coordinates: [34.7818, 32.0853],
        },
      },
      status: "active",
    };

    await request(app)
      .post("/api/users/register")
      .send(registerPayload)
      .expect(201);

    const newEmail = `new_${unique}@example.com`;

    const res = await request(app)
      .put("/api/users/profile")
      .send({
        firebaseUid: `uid_email_${unique}`,
        personalInfo: {
          email: newEmail,
        },
      });

    expect(res.status).toBe(200);
    expect(res.body.personalInfo.email).toBe(newEmail);
  });

});
