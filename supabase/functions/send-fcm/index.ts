// Supabase Edge Function: send FCM push to group members.
// Secrets (Supabase Dashboard → Edge Functions → Secrets):
//   FIREBASE_PROJECT_ID
//   FIREBASE_CLIENT_EMAIL
//   FIREBASE_PRIVATE_KEY  (use \n for newlines in the key)

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface PushRequest {
  user_ids: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

async function getAccessToken(): Promise<string> {
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
  const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, "\n");
  if (!clientEmail || !privateKey) {
    throw new Error("Firebase service account env vars missing");
  }

  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: clientEmail,
      sub: clientEmail,
      aud: "https://oauth2.googleapis.com/token",
      iat: getNumericDate(0),
      exp: getNumericDate(3600),
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    },
    privateKey,
  );

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenJson = await tokenRes.json();
  return tokenJson.access_token as string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    if (!projectId) throw new Error("FIREBASE_PROJECT_ID missing");

    const payload = (await req.json()) as PushRequest;
    const { user_ids, title, body, data = {} } = payload;

    if (!user_ids?.length || !title || !body) {
      return new Response(JSON.stringify({ error: "Invalid payload" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const usersRes = await fetch(
      `${supabaseUrl}/rest/v1/users?id=in.(${user_ids.join(",")})&select=id,fcm_token`,
      {
        headers: {
          apikey: serviceKey,
          Authorization: `Bearer ${serviceKey}`,
        },
      },
    );
    const users = await usersRes.json() as { id: string; fcm_token: string | null }[];
    const tokens = users
      .map((u) => u.fcm_token)
      .filter((t): t is string => !!t && t.length > 0);

    if (tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const accessToken = await getAccessToken();
    let sent = 0;

    for (const token of tokens) {
      const fcmRes = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              data,
              android: {
              priority: "HIGH",
              notification: {
                channel_id: "room_expense_updates",
              },
            },
            },
          }),
        },
      );
      if (fcmRes.ok) sent++;
    }

    return new Response(JSON.stringify({ sent, tokens: tokens.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
