// deno-lint-ignore-file no-import-prefix
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.0";
import { PDFDocument, rgb, StandardFonts } from "https://esm.sh/pdf-lib@1.17.1";

type ArchiveRow = {
  booking_archives_id: number;
  booking_id: number;
  driver_id: number | null;
  passenger_id: string | null;
  route_id: number;
  payment_method: string | null;
  fare: number | null;
  seat_type: string | null;
  ride_status: string | null;
  pickup_address: string | null;
  pickup_lat: number | null;
  pickup_lang: number | null;
  dropoff_address: string | null;
  dropoff_lat: number | null;
  dropoff_lang: number | null;
  start_time: string | null;
  end_time: string | null;
  assigned_at: string | null;
  archived_at: string;
  pdf_path: string | null;
  exported_at: string | null;
};

function envOrThrow(name: string): string {
  const v = Deno?.env?.get?.(name);
  if (!v) throw new Error(`Missing env ${name}`);
  return v;
}

async function generatePdf(row: ArchiveRow): Promise<Uint8Array> {
  const pdf = await PDFDocument.create();
  const page = pdf.addPage([595.28, 841.89]); // A4
  const font = await pdf.embedFont(StandardFonts.Helvetica);
  let y = 800;
  const write = (t: string) => { page.drawText(t, { x: 50, y, size: 12, font, color: rgb(0,0,0) }); y -= 18; };

  write(`Booking Archive ID: ${row.booking_archives_id}`);
  write(`Original Booking ID: ${row.booking_id}`);
  write(`Archived At: ${row.archived_at}`);
  write(`Driver ID: ${row.driver_id ?? "-"}`);
  write(`Passenger ID: ${row.passenger_id ?? "-"}`);
  write(`Route ID: ${row.route_id}`);
  write(`Ride Status: ${row.ride_status ?? "-"}`);
  write(`Fare: ${row.fare ?? "-"}`);
  write(`Payment Method: ${row.payment_method ?? "-"}`);
  write(`Seat Type: ${row.seat_type ?? "-"}`);
  write(`Pickup: ${row.pickup_address ?? "-"} (${row.pickup_lat ?? "-"}, ${row.pickup_lang ?? "-"})`);
  write(`Dropoff: ${row.dropoff_address ?? "-"} (${row.dropoff_lat ?? "-"}, ${row.dropoff_lang ?? "-"})`);
  write(`Start Time: ${row.start_time ?? "-"}`);
  write(`End Time: ${row.end_time ?? "-"}`);
  write(`Assigned At: ${row.assigned_at ?? "-"}`);

  return await pdf.save();
}

serve(async (req) => {
  try {
    const url = new URL(req.url);
    const retentionDays = Number(url.searchParams.get("retentionDays") ?? "365");

    const supabase = createClient(
      envOrThrow("SUPABASE_URL"),
      envOrThrow("SUPABASE_SERVICE_ROLE_KEY")
    );

    const cutoffIso = new Date(Date.now() - retentionDays * 86400_000).toISOString();
    const { data: rows, error: selErr } = await supabase
      .from("booking_archives")
      .select("*")
      .lt("archived_at", cutoffIso)
      .is("exported_at", null)
      .limit(500);
    if (selErr) throw selErr;

    let processed = 0;
    for (const row of (rows ?? []) as ArchiveRow[]) {
      const pdfBytes = await generatePdf(row);
      const d = new Date(row.archived_at);
      const year = String(d.getUTCFullYear());
      const month = String(d.getUTCMonth() + 1).padStart(2, "0");
      const path = `${year}/${month}/booking_${row.booking_id}.pdf`;

      const { error: upErr } = await supabase.storage
        .from("booking-archives")
        .upload(path, pdfBytes, { upsert: true, contentType: "application/pdf" });
      if (upErr) throw upErr;

      const { error: updErr } = await supabase
        .from("booking_archives")
        .update({ pdf_path: path, exported_at: new Date().toISOString() })
        .eq("booking_archives_id", row.booking_archives_id);
      if (updErr) throw updErr;

      processed++;
    }

    return new Response(JSON.stringify({ processed }), { headers: { "content-type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: { "content-type": "application/json" } });
  }
});

