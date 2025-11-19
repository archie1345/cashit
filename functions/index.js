const express = require('express');
const cors = require('cors');
const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const Stripe = require('stripe');
const bcrypt = require('bcrypt');


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
app.use('/api/webhook', express.raw({type: 'application/json'}));

app.use(express.json());

const authenticateFirebaseToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({error: 'Missing or invalid Authorization header'});
    }

    const idToken = authHeader.split(' ')[1];
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

app.get('/api/web-success', (req, res) => {
  res.status(200).send(`
    <html>
      <head><title>Success</title></head>
      <body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
        <h1>Action Complete!</h1>
        <p>Your request was successful. You can now return to the app.</p>
      </body>
    </html>
  `);
});

app.get('/api/web-cancel', (req, res) => {
  res.status(200).send(`
    <html>
      <head><title>Canceled</title></head>
      <body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
        <h1>Action Canceled</h1>
        <p>The process was canceled. You can try again from the app.</p>
      </body>
    </html>
  `);
});

app.get('/api/onboard-success', (req, res) => {
  res.status(200).send(`
    <html>
      <head><title>Success</title></head>
      <body>
        <p>Success! Redirecting you back to the app...</p>
        <script>
          window.location.href = 'cashit://onboarding/success';
          setTimeout(function() {
            window.location.href = 'https://api-cksvvgpqtq-uc.a.run.app/api/web-success';
          }, 2500);
        </script>
      </body>
    </html>
  `);
});

app.get('/api/onboard-refresh', (req, res) => {
  res.status(200).send(`
    <html>
      <head><title>Canceled</title></head>
      <body>
        <p>Redirecting you back to the app...</p>
        <script>
          window.location.href = 'cashit://onboarding/refresh';
          setTimeout(function() {
            window.location.href = 'https://api-cksvvgpqtq-uc.a.run.app/api/web-cancel';
          }, 2500);
        </script>
      </body>
    </html>
  `);
});

app.get('/api/checkout-success', (req, res) => {
  res.status(200).send(`
    <html>
      <head><title>Payment Successful</title></head>
      <body>
        <p>Payment Successful! Redirecting you back to the app...</p>
        <script>
          window.location.href = 'cashit://checkout/success';
          setTimeout(function() {
            window.location.href = 'https://api-cksvvgpqtq-uc.a.run.app/api/web-success';
          }, 2500);
        </script>
      </body>
    </html>
  `);
});

app.get('/api/checkout-cancel', (req, res) => {
  res.status(200).send(`
    <html>
      <head><title>Payment Canceled</title></head>
      <body>
        <p>Payment Canceled. Redirecting you back to the app...</p>
        <script>
          window.location.href = 'cashit://checkout/cancel';
          setTimeout(function() {
            window.location.href = 'https://api-cksvvgpqtq-uc.a.run.app/api/web-cancel';
          }, 2500);
        </script>
      </body>
    </html>
  `);
});

app.post('/api/create-pin', authenticateFirebaseToken, async (req, res) => {
  try {
    const { pin } = req.body;
    const userId = req.user.uid;

    if (!pin || pin.length !== 6 || !/^\d+$/.test(pin)) {
      return res.status(400).json({ error: 'PIN must be a 6-digit number.' });
    }

    const saltRounds = 10;
    const pinHash = await bcrypt.hash(pin, saltRounds);

    await db.collection('users').doc(userId).update({
      pinHash: pinHash,
    });

    res.status(200).json({ message: 'PIN created successfully.' });
  } catch (error) {
    console.error('Error creating PIN:', error);
    res.status(500).json({ error: 'Failed to create PIN.', details: error.message });
  }
});

app.get('/api/get-firestore-balance', authenticateFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({error: 'user account not found.'});
    }

    const balance = userDoc.data()?.balance ?? 0;
    res.status(200).json({balance: balance, currency: 'idr'});
  } catch (error) {
    console.error('Error fetching Firestore balance:', error);
    res.status(500).json({error: error.message});
  }
});

app.get('/api/get-stripe-balance', authenticateFirebaseToken, async (req, res) => {
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
    console.error('Error fetching stripe balance:', error);
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

app.post('/api/webhook', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const stripeSecret = await STRIPE_WEBHOOK_SECRET.value();

  let event;

  try {
    const stripeSecretKey = await STRIPE_SECRET_KEY.value();
    const stripe = new Stripe(stripeSecretKey);

    event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeSecret);
  } catch (err) {
    console.error('Webhook signature verification failed.', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    switch (event.type) {
    case 'payment_intent.succeeded': {
      const paymentIntent = event.data.object;
      if (!paymentIntent.metadata || !paymentIntent.metadata.userId) {
        console.warn('Webhook received payment_intent.succeeded with no userId in metadata. Skipping.');
        return res.status(200).send('Webhook received but skipped: Missing metadata.');
      }
      const {userId, amount, currency} = paymentIntent.metadata;
      const amountInt = parseInt(amount, 10);

      console.log(`PaymentIntent for user ${userId} of amount ${amount} ${currency} succeeded.`);

      try {
        const topupRef = db.collection('topup').doc();
        const userRef = db.collection('users').doc(userId);

        await db.runTransaction(async (t) => {
          t.update(userRef, {
            balance: admin.firestore.FieldValue.increment(amountInt)
          });

          t.set(topupRef, {
            userId: userId,
            amount: amountInt,
            type: 'top-up',
            status: 'completed',
            gateway: 'Stripe',
            gatewayTransactionId: paymentIntent.id,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log('Customer logged top-up and updated balance for user:', userId);
      } catch (err) {
        console.error('Error in top-up webhook transaction:', err);
        return res.status(500).send(`Webhook Transaction Error: ${err.message}`);
      }
      break;
    }

    case 'transfer.created': {
      const transfer = event.data.object;
      console.log(`A transfer was created: ${transfer.id}, Amount: ${transfer.amount}`);
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
app.post('/api/onboard-user-account' ,authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = Stripe(STRIPE_SECRET_KEY.value());
    const userId = req.user.uid;
    const email = req.user.email;
    const { username } = req.body;

    if (!email) {
      return res.status(400).json({error: 'Email is required'});
    }
    console.log(`Onboarding user account for UID=${userId}, email=${email}`);

    const normalizedUsername = username.toLowerCase();
    const usernameQuery = await db.collection('users').where('username', '==', normalizedUsername).get();
    if (!usernameQuery.empty) {
      return res.status(400).json({error: 'Username is already taken'});
    }

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
    await db.collection('users').doc(userId).update({
      stripeAccountId: account.id,
    }, {merge: true});

    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: 'https://api-cksvvgpqtq-uc.a.run.app/api/redirect-refresh',
      return_url: 'https://api-cksvvgpqtq-uc.a.run.app/api/redirect-success',
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
      currency: 'idr',
      automatic_payment_methods: {enabled: true, allow_redirects: 'never'},
      transfer_data: {
        destination: destination,
      },
      metadata: {userId: userId, amount: amount, currency: 'idr'},
    });

    res.status(200).json({clientSecret: paymentIntent.client_secret, paymentIntentId: paymentIntent.id});

  } catch (error) {
    console.error('Error creating top-up intent:', error);
    res.status(400).json({error: error.message});
  }
});

app.post('/api/initiate-transfer', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const {amount, recipientUsername,pin} = req.body;
    const senderId = req.user.uid;

    if (!pin) {
      return res.status(400).json({ error: 'PIN is required for this transaction.' });
    }

    const amountInt = parseInt(amount, 10);
    if (!amountInt || amountInt <= 0 || !recipientUsername) {
      return res.status(400).json({error: 'valid amount and recipient username are required'});
    }

    // Get sender details
    const senderDocRef = db.collection('users').doc(senderId);
    const senderDoc = await senderDocRef.get();
    const senderAccount = senderDoc.data()?.stripeAccountId;
    const senderBalance = senderDoc.data()?.balance ?? 0;
    const pinHash = senderDoc.data()?.pinHash;

    const normalizedUsername = recipientUsername.toLowerCase();

    if (!senderDoc.exists || !senderAccount) {
      return res.status(400).json({error: 'Sender not Found or does not have a Stripe customer ID'});
    }

    if (!pinHash) {
      return res.status(403).json({ error: 'No PIN is set up for this account.' });
    }
    const isPinCorrect = await bcrypt.compare(pin, pinHash);
    if (!isPinCorrect) {
      return res.status(403).json({ error: 'Invalid PIN.' });
    }

    if (senderBalance < amountInt) {
      return res.status(400).json({
        error: 'Insufficient balance for transfer',
        availableBalance: senderBalance,
        required: amountInt,
      });
    }

    const recipientQuery = await db.collection('users').where('username', '==', normalizedUsername).get();
    if (recipientQuery.empty) {
      return res.status(400).json({error: 'Recipient not found'});
    }

    const recipientId = recipientQuery.docs[0].id;
    if (recipientId === senderId) {
      return res.status(400).json({error: 'You cannot send money to yourself.'});
    }

    const recipientDocRef = db.collection('users').doc(recipientId);
    const recipientDoc = await recipientDocRef.get();
    const recipientAccount = recipientDoc.data()?.stripeAccountId;
    if (!recipientDoc.exists || !recipientAccount) {
      return res.status(400).json({error: 'Receipent not found or does not have a Stripe customer ID'});
    }

    const platformAccount = await stripe.account.retrieve();
    const platformAccountId = platformAccount.id;

    const reverseTransfer = await stripe.transfers.create({
      amount: amount,
      currency: 'idr',
      destination: platformAccountId,
      transfer_group: `P2P_${senderId}_${Date.now()}`,
    }, {
      stripeAccount: senderAccount,
    });

    const transfer = await stripe.transfers.create({
      amount: amount,
      currency: 'idr',
      destination: recipientAccount,
      transfer_group: `P2P_${senderId}_${Date.now()}`,
    });

    // Log transfer to Firestore
    const transactionRef = db.collection('transfer').doc();
    await db.runTransaction(async (t) => {
      t.update(senderDocRef, {
        balance: admin.firestore.FieldValue.increment(-amountInt)
      });
      t.update(recipientDocRef, {
        balance: admin.firestore.FieldValue.increment(amountInt)
      });
      t.set(transactionRef, {
        type: 'P2P_TRANSFER',
        amount: amountInt,
        currency: 'idr',
        senderId: senderId,
        recipientId: recipientId,
        stripeDebitTransferId: reverseTransfer.id,
        stripeCreditTransferId: transfer.id,
        status: 'COMPLETED',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    res.status(200).json({message:'p2p transfer successful',transactionId: transactionRef.id});

  } catch (error) {
    console.error('Error initiating transfer:', error);
    res.status(400).json({error: error.message});
  }
});

app.post('/api/create-payout', authenticateFirebaseToken, async (req, res) => {
  try {
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const {amount, pin} = req.body;
    const userId = req.user.uid;
    const amountInt = parseInt(amount, 10);

    if (!amountInt || amount <= 0) {
      return res.status(400).json({error: 'valid amount is required'});
    }

    if (!pin) {
      return res.status(400).json({ error: 'PIN is required for this transaction.' });
    }

    // Get or create customerId
    const userDocRef = db.collection('users').doc(userId);
    const userDoc = await userDocRef.get();
    const stripeAccountId = userDoc.data()?.stripeAccountId;
    const userBalance = userDoc.data()?.balance ?? 0;
    const pinHash = userDoc.data()?.pinHash;

    if (!userDoc.exists || !stripeAccountId) {
      return res.status(400).json({error: 'User does not have a Stripe customer ID'});
    }

    if (!pinHash) {
      return res.status(403).json({ error: 'No PIN is set up for this account.' });
    }
    const isPinCorrect = await bcrypt.compare(pin, pinHash);
    if (!isPinCorrect) {
      return res.status(403).json({ error: 'Invalid PIN.' });
    }

    if (userBalance < amountInt) {
      return res.status(400).json({
        error: 'Insufficient balance for payout',
        availableBalance: userBalance,
        required: amountInt,
      });
    }

    console.log(`Creating payout for UID=${userId}, amount=${amount}, stripeAccountId=${stripeAccountId}`);

    const payout = await stripe.payouts.create({
      amount: amount,
      currency: 'idr',
    },{
      stripeAccount: stripeAccountId,
    });

    const topupRef = db.collection('topup').doc();

    await db.runTransaction(async (t) => {
      t.update(userDocRef, {
        balance: admin.firestore.FieldValue.increment(-amountInt)
      });
      t.set(topupRef, {
        userId: userId,
        amount: amountInt,
        type: 'withdrawal',
        status: payout.status,
        gateway: 'Stripe',
        gatewayChargeId: payout.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    res.status(200).json({
      message: 'Payout initiated successfully.',
      payoutId: payout.id,
      status: payout.status,
      transactionId: topupRef.id,});

  } catch (error) {
    console.error('Error creating payout:', error);
    if (error.code === 'balance_insufficient') {
      return res.status(400).json({error: 'Insufficient available balance for payout.'});
    }
    res.status(500).json({error: error.message || 'Failed to initiate payout.'});
  }
});

app.post('/api/pay-bill',authenticateFirebaseToken, async (req, res) => {
  try{
    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const {amount, billerAccountId, accountNumber, pin} = req.body;
    const senderId = req.user.uid;
    const amountInt = parseInt(amount, 10);

    if (!amountInt || amountInt <= 0 || !billerAccountId || !accountNumber) {
      return res.status(400).json({error: 'valid amount, billerAccountId and accountNumber is required'});
    }

    if (!pin) {
      return res.status(400).json({ error: 'PIN is required for this transaction.' });
    }

    const senderDocRef = db.collection('users').doc(senderId);
    const senderDoc = await senderDocRef.get();
    const senderAccount = senderDoc.data()?.stripeAccountId;
    const senderBalance = senderDoc.data()?.balance ?? 0;
    const pinHash = senderDoc.data()?.pinHash;

    if (!senderDoc.exists || !senderAccount) {
      return res.status(400).json({error: 'Sender not Found or does not have a Stripe customer ID'});
    }

    if (!pinHash) {
      return res.status(403).json({ error: 'No PIN is set up for this account.' });
    }
    const isPinCorrect = await bcrypt.compare(pin, pinHash);
    if (!isPinCorrect) {
      return res.status(403).json({ error: 'Invalid PIN.' });
    }

    if (senderBalance < amountInt) {
      return res.status(400).json({
        error: 'Insufficient balance for bill payment',
        availableBalance: senderBalance,
        require: amountInt,
      });
    }
    const platformAccount = await stripe.account.retrieve(); // Uses the API key's default account
    const platformAccountId = platformAccount.id;

    const reverseTransfer = await stripe.transfers.create({
      amount: amount,
      currency: 'idr',
      destination: platformAccountId,
      transfer_group: `BILL_PAY_${senderId}_${Date.now()}`,
      metadata: {
        accountNumber: accountNumber,
        billerAccountId: billerAccountId,
        // required: amount,
      }
    }, {
      stripeAccount: senderAccount,
    });

    const billerTransfer = await stripe.transfers.create({
      amount: amountInt,
      currency: 'idr',
      destination: billerAccountId,
      transfer_group: `BILL_PAY_${senderId}_${Date.now()}`,
    });

    const topupRef = db.collection('topup').doc();

    await db.runTransaction(async (t) => {
      t.update(senderDocRef, {
        balance: admin.firestore.FieldValue.increment(-amountInt)
      });

      t.set(topupRef, {
        userId: senderId,
        amount: amountInt,
        type: 'bill-payment',
        status: 'completed',
        gateway: 'Stripe',
        gatewayChargeId: reverseTransfer.id,
        gatewayTransactionId: billerTransfer.id,
        billerAccountId: billerAccountId,
        accountNumber: accountNumber,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    res.status(200).json({message:'Bill payment successful',topupid: topupRef.id});
  } catch (error) {
    console.error('Error paying bill:', error);
    res.status(500).json({error: error.message});
  }
});

//get transaction history
app.get('/api/transaction-history', authenticateFirebaseToken, async (req, res) => {
  try {
    const transactionMap = new Map();
    const userId = req.user.uid;

    const sentQuery = db.collection('transfer').where('senderId', '==', userId);
    const receivedQuery = db.collection('transfer').where('recipientId', '==', userId);
    const topupQuery = db.collection('topup').where('userId', '==', userId);

    const [sentSnapshot, receivedSnapshot, topupSnapshot] = await Promise.all([
      sentQuery.get(),
      receivedQuery.get(),
      topupQuery.get(),
    ]);

    sentSnapshot.forEach((doc) => transactionMap.set(doc.id, {id: doc.id, ...doc.data(), direction: 'SENT'}));
    receivedSnapshot.forEach((doc) => transactionMap.set(doc.id, {id: doc.id, ...doc.data(), direction: 'RECEIVED'}));
    topupSnapshot.forEach((doc) => {
      transactionMap.set(doc.id, {id: doc.id, ...doc.data()});
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

    console.log(`Deleting Firestore document for user: ${userId}`);
    await userDocRef.delete();
    console.log('User document deleted successfully.');

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
      return res.status(400).json({error: 'User does not have a Stripe account'});
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'idr',
            product_data: {
              name: 'Top-up Wallet',
            },
            unit_amount: amount*100,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: 'https://api-cksvvgpqtq-uc.a.run.app/api/checkout-success',
      cancel_url: 'https://api-cksvvgpqtq-uc.a.run.app/api/checkout-cancel',
      client_reference_id: userId,
      payment_intent_data: {
        transfer_data: {
          destination: stripeAccountId,
        },
        metadata: {
          userId: userId,
          amount: amount,
          currency: 'idr'
        }
      },
    }
    );

    res.status(200).json({ checkoutUrl: session.url, paymentIntentId: session.payment_intent });
  } catch (error) {
    console.error('Error creating checkout session:', error);
    res.status(500).json({ error: error.message });
  }
});

const ADMIN_SECRET_KEY = 'your-very-strong-unguessable-secret-key-12345';

app.post('/api/admin/delete-orphaned-account', async (req, res) => {
  try {
    const { stripeAccountId, adminSecret } = req.body;

    if (adminSecret !== ADMIN_SECRET_KEY) {
      return res.status(401).json({ error: 'Invalid admin secret.' });
    }

    if (!stripeAccountId) {
      return res.status(400).json({ error: 'stripeAccountId is required.' });
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    console.log(`Admin is deleting Stripe account: ${stripeAccountId}`);
    const deletedStripeAccount = await stripe.accounts.del(stripeAccountId);
    console.log('Stripe account deleted successfully.');

    const userQuery = await db.collection('users').where('stripeAccountId', '==', stripeAccountId).get();

    let firebaseUid = null;

    if (userQuery.empty) {
      console.log('No matching user document found. It might already be deleted.');
    } else {
      for (const doc of userQuery.docs) {
        firebaseUid = doc.id; // Get the Firebase UID from the doc ID
        console.log(`Found matching user doc: ${firebaseUid}. Deleting...`);
        await doc.ref.delete();
        console.log('user document deleted.');
      }
    }

    if (firebaseUid) {
      const userDocRef = db.collection('users').doc(firebaseUid);
      const userDoc = await userDocRef.get();
      if (userDoc.exists) {
        console.log(`Found matching user doc: ${firebaseUid}. Deleting...`);
        await userDocRef.delete();
        console.log('User document deleted.');
      } else {
        console.log('No matching user document found.');
      }
    }

    res.status(200).json({
      message: 'Orphaned account cleanup successful.',
      deletedStripeAccount: deletedStripeAccount,
    });

  } catch (error) {
    console.error('Error in admin delete endpoint:', error);
    if (error.code === 'account_invalid') {
      return res.status(404).json({ error: 'Stripe account not found or already deleted.' });
    }
    res.status(500).json({ error: error.message });
  }
});

exports.api = onRequest({secrets: [STRIPE_SECRET_KEY,CLIENT_ID, WEB_CLIENT_ID,STRIPE_WEBHOOK_SECRET]}, app);
