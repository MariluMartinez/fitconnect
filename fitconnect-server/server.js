const express = require("express");
const axios = require("axios");
const cors = require("cors");

const {
  initializeApp,
  cert,
  getApps,
} = require("firebase-admin/app");

const {
  getAuth,
} = require("firebase-admin/auth");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

function initializeFirebaseAdmin() {
  if (getApps().length > 0) {
    return;
  }

  const serviceAccountJson =
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (!serviceAccountJson) {
    throw new Error(
      "Missing FIREBASE_SERVICE_ACCOUNT_JSON",
    );
  }

  const serviceAccount =
    JSON.parse(serviceAccountJson);

  initializeApp({
    credential: cert(serviceAccount),
  });
}

initializeFirebaseAdmin();

const db = getFirestore();
const auth = getAuth();

function getBasicAuthorizationHeader() {
  const credentials = Buffer.from(
    `${process.env.FITBIT_CLIENT_ID}:${process.env.FITBIT_CLIENT_SECRET}`,
  ).toString("base64");

  return `Basic ${credentials}`;
}

function getTodayInPacificTime() {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Los_Angeles",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

async function verifyFirebaseUser(req, res, next) {
  const authorization = req.headers.authorization;

  if (!authorization?.startsWith("Bearer ")) {
    return res.status(401).json({
      error: "Missing Firebase authorization token",
    });
  }

  const idToken = authorization.substring("Bearer ".length);

  try {
    const decodedToken = await auth.verifyIdToken(idToken); 
    req.firebaseUid = decodedToken.uid;
    next();
  } catch (error) {
    console.error("Firebase token verification failed:", error.message);

    return res.status(401).json({
      error: "Invalid Firebase authorization token",
    });
  }
}

async function saveFitbitTokens(uid, tokens) {
  await db.collection("fitbitTokens").doc(uid).set({
    accessToken: tokens.access_token,
    refreshToken: tokens.refresh_token,
    expiresAt: Date.now() + tokens.expires_in * 1000,
    fitbitUserId: tokens.user_id ?? null,
    scope: tokens.scope ?? null,
    tokenType: tokens.token_type ?? "Bearer",
    updatedAt: FieldValue.serverTimestamp(),
  });
}

async function getFitbitTokens(uid) {
  const doc = await db.collection("fitbitTokens").doc(uid).get();

  if (!doc.exists) {
    return null;
  }

  return doc.data();
}

async function refreshFitbitTokens(uid, savedTokens) {
  const response = await axios.post(
    "https://api.fitbit.com/oauth2/token",
    new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: savedTokens.refreshToken,
    }).toString(),
    {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: getBasicAuthorizationHeader(),
      },
    },
  );

  await saveFitbitTokens(uid, response.data);

  return {
    accessToken: response.data.access_token,
    refreshToken: response.data.refresh_token,
    expiresAt: Date.now() + response.data.expires_in * 1000,
  };
}

async function getValidAccessToken(uid) {
  let savedTokens = await getFitbitTokens(uid);

  if (!savedTokens) {
    return null;
  }

  const expiresSoon =
    !savedTokens.expiresAt ||
    savedTokens.expiresAt <= Date.now() + 60 * 1000;

  if (expiresSoon) {
    savedTokens = await refreshFitbitTokens(uid, savedTokens);
  }

  return savedTokens.accessToken;
}

async function fetchTodayActivity(accessToken) {
  const today = getTodayInPacificTime();

  return axios.get(
    `https://api.fitbit.com/1/user/-/activities/date/${today}.json`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  );
}

app.get("/", (req, res) => {
  res.json({
    status: "FitConnect backend is running",
  });
});

app.post("/exchange-token", verifyFirebaseUser, async (req, res) => {
  const { code } = req.body;
  const uid = req.firebaseUid;

  if (!code) {
    return res.status(400).json({
      error: "Missing authorization code",
    });
  }

  try {
    const tokenResponse = await axios.post(
      "https://api.fitbit.com/oauth2/token",
      new URLSearchParams({
        client_id: process.env.FITBIT_CLIENT_ID,
        grant_type: "authorization_code",
        redirect_uri: process.env.FITBIT_REDIRECT_URI,
        code,
      }).toString(),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Authorization: getBasicAuthorizationHeader(),
        },
      },
    );

    await saveFitbitTokens(uid, tokenResponse.data);

    const activityResponse = await fetchTodayActivity(
      tokenResponse.data.access_token,
    );

    return res.json({
      activity: activityResponse.data,
    });
  } catch (error) {
    console.error(
      "Fitbit token exchange error:",
      error.response?.data || error.message,
    );

    return res.status(500).json({
      error: "Token exchange failed",
      details: error.response?.data || error.message,
    });
  }
});

app.get("/fitbit-data", verifyFirebaseUser, async (req, res) => {
  const uid = req.firebaseUid;

  try {
    const accessToken = await getValidAccessToken(uid);

    if (!accessToken) {
      return res.status(401).json({
        error: "Fitbit is not connected yet",
      });
    }

    const activityResponse = await fetchTodayActivity(accessToken);

    return res.json({
      activity: activityResponse.data,
    });
  } catch (error) {
    console.error(
      "Fitbit data fetch error:",
      error.response?.data || error.message,
    );

    return res.status(500).json({
      error: "Fitbit data fetch failed",
      details: error.response?.data || error.message,
    });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`FitConnect backend running on port ${PORT}`);
});