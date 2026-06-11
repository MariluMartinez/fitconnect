const express = require("express");
const axios = require("axios");
const cors = require("cors");
const fs = require("fs");
require("dotenv").config();

const app = express();
const PORT = 3000;
let fitbitTokens = null;

app.use(cors());
app.use(express.json());

app.post("/exchange-token", async (req, res) => {
  const { code, uid } = req.body;

  if (!uid) {
    return res.status(400).json({ error: "Missing Firebase UID" });
  }

  if (!code) {
    return res.status(400).json({ error: "Missing authorization code" });
  }

  try {
    const tokenResponse = await axios.post(
      "https://api.fitbit.com/oauth2/token",
      new URLSearchParams({
        client_id: process.env.FITBIT_CLIENT_ID,
        grant_type: "authorization_code",
        redirect_uri: process.env.FITBIT_REDIRECT_URI,
        code: code,
      }).toString(),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Authorization:
            "Basic " +
            Buffer.from(
              `${process.env.FITBIT_CLIENT_ID}:${process.env.FITBIT_CLIENT_SECRET}`
            ).toString("base64"),
        },
      }
    );

    const accessToken = tokenResponse.data.access_token;

    const today = new Date().toISOString().split("T")[0];

    const activityResponse = await axios.get(
      `https://api.fitbit.com/1/user/-/activities/date/${today}.json`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      }
    );

    fitbitTokens = tokenResponse.data;

    const tokenFile = `fitbit_tokens_${uid}.json`;
    fs.writeFileSync(tokenFile, JSON.stringify(fitbitTokens, null, 2));
    console.log("Saved Fitbit tokens.");

    res.json({
      tokens: fitbitTokens,
      activity: activityResponse.data,
    });
  } catch (error) {
    console.error(
      "Fitbit token exchange error:",
      error.response?.data || error.message
    );

    res.status(500).json({
      error: "Token exchange failed",
      details: error.response?.data || error.message,
    });
  }
});

app.get("/fitbit-data", async (req, res) => {
  const { uid } = req.query;

  if (!uid) {
    return res.status(400).json({
      error: "Missing Firebase UID",
    });
  }

  const tokenFile = `fitbit_tokens_${uid}.json`;

  if (!fs.existsSync(tokenFile)) {
    return res.status(401).json({
      error: "Fitbit is not connected yet",
    });
  }

  const userTokens = JSON.parse(fs.readFileSync(tokenFile, "utf8"));

  try {
    const today = new Intl.DateTimeFormat("en-CA", {
      timeZone: "America/Los_Angeles",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(new Date());

    console.log("Fetching Fitbit date:", today);

    const activityResponse = await axios.get(
      `https://api.fitbit.com/1/user/-/activities/date/${today}.json`,
      {
        headers: {
          Authorization: `Bearer ${userTokens.access_token}`,
        },
      }
    );

    res.json({
      activity: activityResponse.data,
    });
  } catch (error) {
    console.error(
      "Fitbit data fetch error:",
      error.response?.data || error.message
    );

    res.status(500).json({
      error: "Fitbit data fetch failed",
      details: error.response?.data || error.message,
    });
  }
});

app.listen(PORT, () => {
  console.log(`Fitbit backend running on http://localhost:${PORT}`);
});