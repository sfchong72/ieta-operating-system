/** IEOS uses the Kuala Lumpur business clock (also used by daily output/dashboard SQL). */
const businessClock = new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Kuala_Lumpur", year: "numeric", month: "2-digit", day: "2-digit",
  hour: "2-digit", minute: "2-digit", hourCycle: "h23",
});

export function toBusinessLocalInput(value?: string | null): string {
  if (!value) return "";
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) throw new Error("Invalid date and time.");
  const parts = Object.fromEntries(businessClock.formatToParts(date).map(part => [part.type, part.value]));
  return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}`;
}

export function fromBusinessLocalInput(value: string | null): string | null {
  if (!value) return null;
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(value)) {
    throw new Error("Enter a valid date and time in MYT (UTC+8).");
  }
  const date = new Date(`${value}:00+08:00`);
  if (!Number.isFinite(date.getTime()) || toBusinessLocalInput(date.toISOString()) !== value) {
    throw new Error("Enter a valid date and time in MYT (UTC+8).");
  }
  return date.toISOString();
}
