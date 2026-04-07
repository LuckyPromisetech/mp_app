require('dotenv').config();
const functions = require("firebase-functions");
const axios = require("axios");
const admin = require("firebase-admin");

admin.initializeApp();

const secretKey = process.env.FLUTTERWAVE_SECRET_KEY;
/**
 * 🔹 PAY (Normal Order)
 */
exports.pay = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

    const { amount, email, phone, buyerName } = req.body;

    if (!amount || !email || !buyerName) {
      return res.status(400).json({ status: "error", message: "Missing required fields" });
    }

    const txRef = `ORDER_${Date.now()}`;

    const response = await axios.post(
      "https://api.flutterwave.com/v3/payments",
      {
        tx_ref: txRef,
        amount: amount.toString(),
        currency: "NGN",
        customer: {
          email,
          phonenumber: phone || "08000000000",
          name: buyerName,
        },
        customizations: {
          title: "EdgeBaz",
          description: "Normal Order Payment",
        },
      },
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
          "Content-Type": "application/json",
        },
      }
    );

    const fwData = response.data;

    if (fwData.status === "success") {
      return res.json({
        status: "success",
        link: fwData.data.link,
        tx_ref: txRef,
      });
    }

    return res.status(500).json({ status: "error", details: fwData });

  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.response?.data || err.message });
  }
});

/**
 * 🔹 PROMOTE
 */
exports.promote = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

    const { amount, email, phone, buyerName, productId, duration } = req.body;

    if (!amount || !email || !buyerName || !productId || !duration) {
      return res.status(400).json({ status: "error", message: "Missing required fields" });
    }

    const txRef = `PROMO_${Date.now()}`;

    const response = await axios.post(
      "https://api.flutterwave.com/v3/payments",
      {
        tx_ref: txRef,
        amount: amount.toString(),
        currency: "NGN",
        customer: {
          email,
          phonenumber: phone || "08000000000",
          name: buyerName,
        },
        customizations: {
          title: "EdgeBaz",
          description: `Promotion for ${productId} (${duration} days)`,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
        },
      }
    );

    const fwData = response.data;

    if (fwData.status === "success") {
      return res.json({
        status: "success",
        link: fwData.data.link,
        tx_ref: txRef,
      });
    }

    return res.status(500).json({ status: "error", details: fwData });

  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.response?.data || err.message });
  }
});

/**
 * 🔹 VERIFY PAYMENT
 */
exports.verifyPayment = functions.https.onRequest(async (req, res) => {
  try {
    const { tx_ref } = req.query;

    if (!tx_ref) return res.status(400).json({ error: "Missing tx_ref" });

    const response = await axios.get(
      `https://api.flutterwave.com/v3/transactions/verify_by_tx_ref?tx_ref=${tx_ref}`,
      {
        headers: { Authorization: `Bearer ${secretKey}` },
      }
    );

    const data = response.data;

    if (data.status === "success" && data.data.status === "successful") {
      return res.json({ status: "success", paid: true, details: data.data });
    }

    return res.json({ status: "failed", paid: false });

  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.response?.data || err.message });
  }
});

/**
 * 🔹 PAYOUT
 */
exports.payout = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

    const { sellerId, amount, orderId } = req.body;

    if (!sellerId || !amount || !orderId) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const sellerDoc = await admin.firestore().collection("sellers").doc(sellerId).get();

    if (!sellerDoc.exists) {
      return res.status(404).json({ error: "Seller not found" });
    }

    const seller = sellerDoc.data();

    if (!seller.account || !seller.account.verified) {
      return res.status(400).json({ error: "Seller account not verified" });
    }

    const payoutAmount = amount - amount * 0.075;

    const response = await axios.post(
      "https://api.flutterwave.com/v3/payouts",
      {
        account_bank: seller.account.bankCode,
        account_number: seller.account.accountNumber,
        amount: payoutAmount,
        currency: "NGN",
        narration: `Order ${orderId}`,
        reference: `payout-${orderId}-${Date.now()}`,
      },
      {
        headers: {
          Authorization: `Bearer ${secretKey}`,
        },
      }
    );

    await admin.firestore().collection("sellers").doc(sellerId).update({
      "wallet.balance": admin.firestore.FieldValue.increment(payoutAmount),
      "wallet.pending": admin.firestore.FieldValue.increment(-payoutAmount),
    });

    res.json({ status: "success", data: response.data });

  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.response?.data || err.message });
  }
});