const express = require("express");
const stripe = require("stripe")("sk_test_51PlVh8P9Bz7XrwZPWSkDzX7AmaNgVr04yPOQWnbAECiYSWKtsmmVgD2Z8JYBY8a5dmEfKXaTewrBESb3fxIliwDo00HdJmKBKz");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// Route to create a Stripe Customer
app.post("/create-customer", async (req, res) => {
    const { email, name } = req.body;

    try {
        // Create a new customer in Stripe
        const customer = await stripe.customers.create({
            email: email,
            name: name,
        });

        res.status(200).send({ customerId: customer.id });
    } catch (error) {
        res.status(500).send({ error: error.message });
    }
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
