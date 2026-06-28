import type { EsewaPaymentForm } from "@/types";

export function formatNpr(amount: number): string {
  return new Intl.NumberFormat("en-NP", {
    style: "currency",
    currency: "NPR",
    maximumFractionDigits: 0,
  }).format(amount);
}

export function submitEsewaPayment(paymentUrl: string, form: EsewaPaymentForm): void {
  if (typeof document === "undefined") return;

  const formEl = document.createElement("form");
  formEl.method = "POST";
  formEl.action = paymentUrl;

  for (const [name, value] of Object.entries(form)) {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    formEl.appendChild(input);
  }

  document.body.appendChild(formEl);
  formEl.submit();
}
