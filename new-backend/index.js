require('dotenv').config();
const express = require('express');
const axios = require('axios');
const bodyParser = require('body-parser');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize Firebase Admin SDK from env var
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

app.use(cors());
app.use(bodyParser.json());

// Middleware for authenticating sensitive requests
const authenticate = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Utility to validate phone
const isValidPhone = (phone) => /^[0-9]{10,15}$/.test(phone);

/**
 * 🔹 Normal Payment
 */
app.post('/pay', async (req, res) => {
  try {
    const { amount, email, phone, buyerName } = req.body;
    if (!amount || !email || !buyerName || !phone || !isValidPhone(phone)) {
      return res.status(400).json({ status: 'error', message: 'Missing or invalid fields' });
    }

    const secretKey = process.env.FLUTTERWAVE_SECRET_KEY;
    if (!secretKey) return res.status(500).json({ status: 'error', message: 'Server misconfigured' });

    const txRef = `ORDER_${Date.now()}`;
    const fwResponse = await axios.post(
      'https://api.flutterwave.com/v3/payments',
      {
        tx_ref: txRef,
        amount: amount.toString(),
        currency: 'NGN',
        customer: { email, phonenumber: phone, name: buyerName },
        customizations: { title: 'EdgeBaz', description: 'Normal Order Payment' },
      },
      { headers: { Authorization: `Bearer ${secretKey}`, 'Content-Type': 'application/json' } }
    );

    if (fwResponse.data?.status === 'success') {
      return res.json({ status: 'success', link: fwResponse.data.data.link, tx_ref: txRef });
    } else {
      return res.status(500).json({ status: 'error', message: 'Failed to create payment link', details: fwResponse.data });
    }
  } catch (error) {
    console.error("PAY ERROR:", error.response?.data || error.message);
    res.status(500).json({ status: 'error', message: error.response?.data || error.message });
  }
});

/**
 * 🔹 Payout (protected)
 */
app.post('/payout', authenticate, async (req, res) => {
  try {
    const { sellerId, amount, orderId } = req.body;
    if (!sellerId || !amount || !orderId) return res.status(400).json({ error: 'Missing required fields' });

    const secretKey = process.env.FLUTTERWAVE_SECRET_KEY;
    if (!secretKey) return res.status(500).json({ error: 'Server misconfigured' });

    const sellerDoc = await admin.firestore().collection('sellers').doc(sellerId).get();
    if (!sellerDoc.exists) return res.status(404).json({ error: 'Seller not found' });

    const seller = sellerDoc.data();
    if (!seller.account?.verified) return res.status(400).json({ error: 'Seller account not verified' });

    const payoutAmount = amount - amount * 0.075;
    const fwPayout = await axios.post(
      'https://api.flutterwave.com/v3/payouts',
      {
        account_bank: seller.account.bankCode,
        account_number: seller.account.accountNumber,
        amount: payoutAmount,
        currency: 'NGN',
        narration: `Order Payout ${orderId}`,
        reference: `payout-${orderId}-${Date.now()}`,
      },
      { headers: { Authorization: `Bearer ${secretKey}`, 'Content-Type': 'application/json' } }
    );

    await admin.firestore().collection('sellers').doc(sellerId).update({
      "wallet.balance": admin.firestore.FieldValue.increment(payoutAmount),
      "wallet.pending": admin.firestore.FieldValue.increment(-payoutAmount),
      "transactions": admin.firestore.FieldValue.arrayUnion({
        type: 'payout',
        amount: payoutAmount,
        orderId,
        timestamp: admin.firestore.Timestamp.now(),
        status: fwPayout.data.status,
      }),
    });

    res.json({ status: 'success', data: fwPayout.data });
  } catch (err) {
    console.error("PAYOUT ERROR:", err.response?.data || err.message);
    res.status(500).json({ status: 'error', message: err.response?.data || err.message });
  }
});

/**
 * 🔹 Webhook Endpoint (Flutterwave sends POST here)
 */
app.post('/webhook', async (req, res) => {
  const secretHash = req.headers['verif-hash'];
  if (secretHash !== process.env.FLUTTERWAVE_SECRET_HASH) return res.status(401).send('Unauthorized');

  const event = req.body;
  console.log('📥 Webhook event:', event);

  // Handle successful payment
  if (event.event === 'charge.completed' && event.data.status === 'successful') {
    // Update order/payment in Firestore
  }

  res.status(200).send('OK');
});

app.listen(PORT, '0.0.0.0', () => console.log(`🚀 Backend running on port ${PORT}`));