// =============================================================================
// Supabase Edge Function: invite-employee
// CASEYA Dairy Plant ERP — Secure Administrative Employee Provisioning
// =============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseServiceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfiguration: Service role key missing" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Verify caller authentication
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user: callerUser }, error: callerError } = await callerClient.auth.getUser();
    if (callerError || !callerUser) {
      return new Response(
        JSON.stringify({ error: "Invalid caller credentials" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Authorize caller is an Admin in employee_profiles
    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);
    const { data: callerProfile, error: profileError } = await adminClient
      .from("employee_profiles")
      .select("role, account_status")
      .eq("id", callerUser.id)
      .single();

    if (profileError || callerProfile?.role !== "Admin" || callerProfile?.account_status !== "active") {
      return new Response(
        JSON.stringify({ error: "Access Denied: Only active administrators can invite employees" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Parse and validate request body
    const body = await req.json();
    const { email, full_name, role, employee_code, department } = body;

    if (!email || !full_name || !role) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: email, full_name, and role are mandatory" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const validRoles = ["Admin", "Plant Manager", "Employee"];
    if (!validRoles.includes(role)) {
      return new Response(
        JSON.stringify({ error: "Invalid role specified" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Send official Supabase invitation via Auth Admin API
    const { data: inviteData, error: inviteError } = await adminClient.auth.admin.inviteUserByEmail(
      email.trim(),
      {
        data: {
          full_name: full_name.trim(),
          role: role,
          employee_code: (employee_code || "EMP-01").trim(),
          department: department || "Processing & Operations",
        },
      }
    );

    if (inviteError) {
      return new Response(
        JSON.stringify({ error: inviteError.message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Ensure profile row exists with 'invited' status
    if (inviteData?.user?.id) {
      await adminClient.from("employee_profiles").upsert({
        id: inviteData.user.id,
        email: email.trim(),
        full_name: full_name.trim(),
        role: role,
        employee_code: (employee_code || "EMP-01").trim(),
        department: department || "Processing & Operations",
        account_status: "invited",
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Invitation successfully sent to ${email}`,
        user: inviteData.user,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
