const express = require('express');
const cors = require('cors');
const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const Stripe = require('stripe');
const bodyParser = require('body-parser');


// Define secret
const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const CLIENT_ID = defineSecret('CLIENT_ID');
const STRIPE_WEBHOOK_SECRET = defineSecret('STRIPE_WEBHOOK_SECRET');
const WEB_CLIENT_ID = defineSecret('WEB_CLIENT_ID');

// Init Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const app = express();

app.use(cors({origin: true}));
app.use(bodyParser.json());

const authenticateFirebaseToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({error: 'Missing or invalid Authorization header'});
    }

    const idToken = authHeader.split(' ')[1];
    // Verify the Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = {uid: decodedToken.uid, email: decodedToken.email};
    next();
  } catch (err) {
    console.error('Firebase ID token verification failed:', err.message);
    return res.status(401).json({error: 'Unauthorized'});
  }
};

app.get('/api/config', (req, res) => {
  try {
    res.status(200).json({
      googleClientId: WEB_CLIENT_ID.value(),
    });
  } catch (error) {
    res.status(500).json({error: 'Could not retrieve server configuration.'});
  }
});

app.get('/api/health', (req, res) => {
  res.status(200).send('OK');
});

app.get('/api/get-balance', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const userId = req.user.uid;

    const userDoc = await db.collection('users').doc(userId).get();
    const stripeAccountId = userDoc.data()?.stripeAccountId;
    if (!userDoc.exists || !stripeAccountId) {
      return res.status(404).json({error: 'User not found or has no Stripe account.'});
    }

    const balance = await stripe.balance.retrieve({
      stripeAccount: stripeAccountId,
    });

    res.status(200).json(balance);
  } catch (error) {
    console.error('Error fetching balance:', error);
    res.status(500).json({error: error.message});
  }
});

app.get('/api/get-platform-balance', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const balance = await stripe.balance.retrieve();
    res.status(200).json(balance);
  } catch (error) {
    console.error('Error fetching platform balance:', error);
    res.status(500).json({error: error.message});
  }
});


app.post('/api/webhook', bodyParser.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const stripeSecret = await STRIPE_WEBHOOK_SECRET.value();

  let event;

  try {
    const stripeSecretKey = await STRIPE_SECRET_KEY.value();
    const stripe = new Stripe(stripeSecretKey);

    event = stripe.webhooks.constructEvent(req.body, sig, stripeSecret);
  } catch (err) {
    console.error('Webhook signature verification failed.', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    switch (event.type) {
    case 'payment_intent.succeeded': {
      const paymentIntent = event.data.object;
      const {userId, amount, currency} = paymentIntent.metadata;

      console.log(`PaymentIntent for user ${userId} of amount ${amount} ${currency} succeeded.`);

      await db.collection('transactions').add({
        userId: userId,
        type: 'TOP_UP',
        amount: parseInt(amount, 10),
        currency: currency,
        paymentIntentId: paymentIntent.id,
        status: 'Completed',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log('Customer logged top-up for user:', userId);
      break;
    }

    default:
      console.log(`Unhandled event type ${event.type}`);
    }

    res.status(200).send('Webhook received');
  } catch (err) {
    console.error('Error handling webhook:', err);
    res.status(500).send('Internal Server Error');
  }
});

// creating  a stripe connected account
app.post('/api/onboard-user-account', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = Stripe(STRIPE_SECRET_KEY.value());
    const userId = req.user.uid;
    const email = req.user.email;
    const { username } = req.body;

    if (!email) {
      return res.status(400).json({error: 'Email is required'});
    }
    console.log(`Onboarding user account for UID=${userId}, email=${email}`);

    const account = await stripe.accounts.create({
      type: 'express',
      email: email,
      business_profile: {
        name: username,
      },
      capabilities: {
        transfers: {requested: true},
        card_payments: {requested: true},
      },
      metadata: {appUserId: userId},
    });

    // Save the Stripe customer ID to Firestore
    await db.collection('users').doc(userId).set({
      stripeAccountId: account.id,
      email: email,
      username: username || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: 'https://impliably-unspirited-eleonora.ngrok-free.dev/api/reauth',
      return_url: 'https://impliably-unspirited-eleonora.ngrok-free.dev/api/return',
      type: 'account_onboarding',
    });

    res.status(200).json({onboardingUrl: accountLink.url});
  } catch (error) {
    console.error('Error creating Stripe connect account:', error);
    res.status(500).json({error: error.message});
  }
});


// Create top-up intent
app.post('/api/create-top-up-intent', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const {amount} = req.body;
    const userId = req.user.uid;

    if (!amount || amount <= 0) {
      return res.status(400).json({error: 'valid amount is required'});
    }

    // Get or create customerId
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists || !userDoc.data().stripeAccountId) {
      return res.status(400).json({error: 'User does not have a Stripe customer ID'});
    }
    const destination = userDoc.data().stripeAccountId;

    console.log(`Creating top-up intent for UID=${userId}, amount=${amount}, destination=${destination}`);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'usd',
      automatic_payment_methods: {enabled: true, allow_redirects: 'never'},
      transfer_data: {
        destination: destination,
      },
      metadata: {userId: userId, amount: amount, currency: 'usd'},
    });

    res.status(200).json({clientSecret: paymentIntent.client_secret});

  } catch (error) {
    console.error('Error creating top-up intent:', error);
    res.status(400).json({error: error.message});
  }
});

app.post('/api/initiate-transfer', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const {amount, recipientId} = req.body;
    const senderId = req.user.uid;

    if (!amount || amount <= 0 || !recipientId) {
      return res.status(400).json({error: 'valid amount and recipientId is required'});
    }

    // Get sender details
    const senderDoc = await db.collection('users').doc(senderId).get();
    const senderAccount = senderDoc.data().stripeAccountId;
    if (!senderDoc.exists || !senderAccount) {
      return res.status(400).json({error: 'Sender not Found or does not have a Stripe customer ID'});
    }

    const balance = await stripe.balance.retrieve({
    },{
      stripeAccount: senderAccount,
    });

    const availableBalance = balance.available.find((b) => b.currency === 'usd')?.amount ?? 0;
    if (!availableBalance || availableBalance.amount < amount) {
      return res.status(400).json({
        error: 'Insufficient balance for transfer',
        availableBalance: availableBalance ? availableBalance.amount : 0,
        require: amount});
    }

    // Get receipent details
    const receipentDoc = await db.collection('users').doc(recipientId).get();
    const receipentAccount = receipentDoc.data().stripeAccountId;
    if (!receipentDoc.exists || !receipentAccount) {
      return res.status(400).json({error: 'Receipent not found or does not have a Stripe customer ID'});
    }

    const platformAccount = await stripe.account.retrieve(); // Uses the API key's default account
    const platformAccountId = platformAccount.id;

    const reverseTransfer = await stripe.transfers.create({
      amount: amount,
      currency: 'usd',
      destination: platformAccountId,
      transfer_group: `P2P_${senderId}_${Date.now()}`,
    }, {
      stripeAccount: senderAccount,
    });

    const transfer = await stripe.transfers.create({
      amount: amount,
      currency: 'usd',
      destination: receipentAccount,
      transfer_group: `P2P_${senderId}_${Date.now()}`,
    });

    // Log transfer to Firestore
    await db.collection('transactions').doc().set({
      type: 'P2P_TRANSFER',
      amount: parseInt(amount, 10),
      currency: 'usd',
      senderId: senderId,
      recipientId: recipientId,
      // transferId: transfer.id,
      stripeDebitTransferId: reverseTransfer.id,
      stripeCreditTransferId: transfer.id,
      // stripeTransferToPlatformId: transferToPlatform.id,
      // stripeTransferToRecipientId: transferToReceipent.id,
      status: 'COMPLETED',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    res.status(200).json({message:'p2p transfer successful'});

  } catch (error) {
    console.error('Error initiating transfer:', error);
    res.status(400).json({error: error.message});
  }
});

app.post('/api/create-payout', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const {amount} = req.body;
    const userId = req.user.uid;

    if (!amount || amount <= 0) {
      return res.status(400).json({error: 'valid amount is required'});
    }

    // Get or create customerId
    const userDoc = await db.collection('users').doc(userId).get();
    const stripeAccountId = userDoc.data().stripeAccountId;
    if (!userDoc.exists || !stripeAccountId) {
      return res.status(400).json({error: 'User does not have a Stripe customer ID'});
    }

    console.log(`Creating payout for UID=${userId}, amount=${amount}, stripeAccountId=${stripeAccountId}`);

    const payout = await stripe.payouts.create({
      amount: amount,
      currency: 'usd',
    },{
      stripeAccount: stripeAccountId,
    });

    await db.collection('transactions').add({
      userId: userId,
      type: 'PAYOUT',
      amount: parseInt(amount, 10),
      currency: 'usd',
      stripeAccountId: stripeAccountId,
      stripePayoutId: payout.id,
      status: payout.status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({
      message: 'Payout initiated successfully.',
      payoutId: payout.id,
      status: payout.status,});

  } catch (error) {
    console.error('Error creating payout:', error);
    if (error.code === 'balance_insufficient') {
      return res.status(400).json({error: 'Insufficient available balance for payout.'});
    }
    res.status(500).json({error: error.message || 'Failed to initiate payout.'});
  }
});

//get transaction history
app.get('/api/transaction-history', authenticateFirebaseToken, async (req, res) => {
  try {
    const transactionMap = new Map();
    const userId = req.user.uid;

    const sentQuery = db.collection('transactions').where('senderId', '==', userId);
    const receivedQuery = db.collection('transactions').where('recipientId', '==', userId);
    const userActionQuery = db.collection('transactions').where('userId', '==', userId);

    const [sentSnapshot, receivedSnapshot, userActionSnapshot] = await Promise.all([
      sentQuery.get(),
      receivedQuery.get(),
      userActionQuery.get(),
    ]);

    sentSnapshot.forEach((doc) => transactionMap.set(doc.id, {id: doc.id, ...doc.data(), direction: 'SENT'}));
    receivedSnapshot.forEach((doc) => transactionMap.set(doc.id, {id: doc.id, ...doc.data(), direction: 'RECEIVED'}));
    userActionSnapshot.forEach((doc) => {
      if (!transactionMap.has(doc.id)) {
        transactionMap.set(doc.id, {id: doc.id, ...doc.data(), direction: doc.data().type});
      }
    });
    const uniqueTransactions = Array.from(transactionMap.values());
    uniqueTransactions.sort((a, b) => b.createdAt.toMillis() - a.createdAt.toMillis());

    res.status(200).json({transactions: uniqueTransactions});
  } catch (error) {
    console.error('Error fetching transaction history:', error);
    res.status(500).json({error: error.message});
  }
});

// Delete user account and associated data
app.delete('/api/delete-user-account', authenticateFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    console.log(`Attempting to delete user account for UID=${userId}`);
    if (!userId) {
      return res.status(400).json({error: 'User ID is required'});
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const userDocRef = db.collection('users').doc(userId);

    const userDoc = await userDocRef.get();
    if (userDoc.exists && userDoc.data().stripeAccountId) {
      const stripeAccountId = userDoc.data().stripeAccountId;

      console.log(`Deleting Stripe account: ${stripeAccountId}`);
      await stripe.accounts.del(stripeAccountId);
      console.log('Stripe account deleted successfully.');
    }

    console.log(`Deleting Firestore document for user: ${userId}`);
    await userDocRef.delete();
    console.log('Firestore document deleted successfully.');

    console.log(`Deleting user from Firebase Auth: ${userId}`);
    await admin.auth().deleteUser(userId);
    console.log('Firebase Auth user deleted successfully.');

    res.status(200).json({message: 'User account deleted successfully from all services.'});
  } catch (error) {
    console.error('Error deleting user account:', error);
    res.status(500).json({error: 'Failed to delete user account.', details: error.message});
  }
});

app.post('/api/create-checkout-session', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const { amount } = req.body;
    const userId = req.user.uid;

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid amount is required' });
    }

    const userDoc = await db.collection('users').doc(userId).get();
    const stripeAccountId = userDoc.data()?.stripeAccountId;
    if (!userDoc.exists || !stripeAccountId) {
      return res.status(400).json({ error: 'User does not have a Stripe account' });
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'Top-up Wallet',
            },
            unit_amount: amount,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: 'https://impliably-unspirited-eleonora.ngrok-free.dev/api/return',
      cancel_url: 'https://impliably-unspirited-eleonora.ngrok-free.dev/api/return',
      client_reference_id: userId,
      payment_intent_data: {
        transfer_data: {
          destination: stripeAccountId,
        },
      },
    }
    );

    res.status(200).json({ checkoutUrl: session.url });
  } catch (error) {
    console.error('Error creating checkout session:', error);
    res.status(500).json({ error: error.message });
  }
});

exports.api = onRequest({secrets: [STRIPE_SECRET_KEY,CLIENT_ID, WEB_CLIENT_ID,STRIPE_WEBHOOK_SECRET]}, app);
