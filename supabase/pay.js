import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// Load Flutterwave secret from Supabase secret
const FLW_SECRET_KEY = Deno.env.get("FLUTTERWAVE_SECRET_KEY");

serve(async (req) => {
  try {
    const { amount, email, phone, buyerName } = await req.json();

    if (!amount || !email || !buyerName) {
      return new Response(JSON.stringify({ status: "error", message: "Missing required fields" }), { status: 400 });
    }

    const txRef = `ORDER_${Date.now()}`;

    const response = await fetch("https://api.flutterwave.com/v3/payments", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${FLW_SECRET_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        tx_ref: txRef,
        amount: amount.toString(),
        currency: "NGN",
        customer: { email, phonenumber: phone || "08000000000", name: buyerName },
        customizations: { title: "EdgeBaz", description: "Normal Order Payment" },
      }),
    });

    const data = await response.json();

    if (data.status === "success") {
      return new Response(JSON.stringify({ status: "success", link: data.data.link, tx_ref: txRef }), {
        headers: { "Content-Type": "application/json" },
      });
    } else {
      return new Response(JSON.stringify({ status: "error", details: data }), { status: 500 });
    }
  } catch (err) {
    return new Response(JSON.stringify({ status: "error", message: err.message }), { status: 500 });
  }
});